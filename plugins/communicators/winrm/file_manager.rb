require "log4r"

module VagrantPlugins
  module CommunicatorWinRM
    # Manages the file system on the remote guest allowing for file tranfer
    # between the guest and host.
    class FileManager
      def initialize(shell)
        @logger = Log4r::Logger.new("vagrant::communication::filemanager")
        @shell = shell
      end

      # Uploads the given file or directory from the host to the guest (recursively).
      #
      # @param [String] The source file or directory path on the host
      # @param [String] The destination file or directory path on the host
      def upload(host_src_file_path, guest_dest_file_path)
        @logger.debug("Upload: #{host_src_file_path} -> #{guest_dest_file_path}")
        if File.directory?(host_src_file_path)
          upload_directory(host_src_file_path, guest_dest_file_path)
        else
          upload_file(host_src_file_path, guest_dest_file_path)
        end
      end

      # Downloads the given file from the guest to the host.
      # NOTE: This currently only supports single file download
      #
      # @param [String] The source file path on the guest
      # @param [String] The destination file path on the host
      def download(guest_src_file_path, host_dest_file_path)
        @logger.debug("#{guest_src_file_path} -> #{host_dest_file_path}")

        output = @shell.powershell("[System.convert]::ToBase64String([System.IO.File]::ReadAllBytes(\"#{guest_src_file_path}\"))")
        contents = output[:data].map!{|line| line[:stdout]}.join.gsub("\\n\\r", '')
        out = Base64.decode64(contents)
        IO.binwrite(host_dest_file_path, out)
      end

      private

      # Recursively uploads the given directory from the host to the guest
      #
      # @param [String] The source file or directory path on the host
      # @param [String] The destination file or directory path on the host
      def upload_directory(host_src_file_path, guest_dest_file_path)
        glob_patt = File.join(host_src_file_path, '**/*')
        Dir.glob(glob_patt).select { |f| !File.directory?(f) }.each do |host_file_path|
          guest_file_path = guest_file_path(host_src_file_path, guest_dest_file_path, host_file_path)
          upload_file(host_file_path, guest_file_path)
        end
      end

      # Uploads the given file, but only if the target file doesn't exist
      # or its MD5 checksum doens't match the host's source checksum.
      #
      # @param [String] The source file path on the host
      # @param [String] The destination file path on the guest
      def upload_file(host_src_file_path, guest_dest_file_path)
        if should_upload_file?(host_src_file_path, guest_dest_file_path)
          tmp_file_path = upload_to_temp_file(host_src_file_path)
          decode_temp_file(tmp_file_path, guest_dest_file_path)
        else
          @logger.debug("Up to date: #{guest_dest_file_path}")
        end
      end

      # Uploads the given file to a new temp file on the guest
      #
      # @param [String] The source file path on the host
      # @return [String] The temp file path on the guest
      def upload_to_temp_file(host_src_file_path)
        tmp_file_path = File.join(guest_temp_dir, "winrm-upload-#{rand()}")
        @logger.debug("Uploading '#{host_src_file_path}' to temp file '#{tmp_file_path}'")

        base64_host_file = Base64.encode64(IO.binread(host_src_file_path)).gsub("\n",'')
        if base64_host_file.empty?
          out = @shell.powershell("New-Item #{tmp_file_path} -type file")
          raise_upload_error_if_failed(out, host_src_file_path, tmp_file_path)
        else
          base64_host_file.chars.to_a.each_slice(8000-tmp_file_path.size) do |chunk|
            out = @shell.cmd("echo #{chunk.join} >> \"#{tmp_file_path}\"")
            raise_upload_error_if_failed(out, host_src_file_path, tmp_file_path)
          end
        end

        tmp_file_path
      end

      # Moves and decodes the given file temp file on the guest to its
      # permanent location
      #
      # @param [String] The source base64 encoded temp file path on the guest
      # @param [String] The destination file path on the guest
      def decode_temp_file(guest_tmp_file_path, guest_dest_file_path)
        @logger.debug("Decoding temp file '#{guest_tmp_file_path}' to '#{guest_dest_file_path}'")
        out = @shell.powershell <<-EOH
          $tmp_file_path = [System.IO.Path]::GetFullPath('#{guest_tmp_file_path}')
          $dest_file_path = [System.IO.Path]::GetFullPath('#{guest_dest_file_path}')

          if (Test-Path $dest_file_path) {
            rm $dest_file_path
          }
          else {
            $dest_dir = ([System.IO.Path]::GetDirectoryName($dest_file_path))
            New-Item -ItemType directory -Force -Path $dest_dir
          }

          $base64_string = Get-Content $tmp_file_path
          if ($base64_string -eq $null) {
            New-Item -ItemType file $dest_file_path
          } else {
            $bytes = [System.Convert]::FromBase64String($base64_string)
            [System.IO.File]::WriteAllBytes($dest_file_path, $bytes)
          }
        EOH
        raise_upload_error_if_failed(out, guest_tmp_file_path, guest_dest_file_path)
      end

      # Checks to see if the target file on the guest is missing or out of date.
      #
      # @param [String] The source file path on the host
      # @param [String] The destination file path on the guest
      # @return [Boolean] True if the file is missing or out of date
      def should_upload_file?(host_src_file_path, guest_dest_file_path)
        local_md5 = Digest::MD5.file(host_src_file_path).hexdigest
        cmd = <<-EOH
          $dest_file_path = [System.IO.Path]::GetFullPath('#{guest_dest_file_path}')

          if (Test-Path $dest_file_path) {
            $crypto_provider = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
            try {
              $file = [System.IO.File]::Open($dest_file_path, [System.IO.Filemode]::Open, [System.IO.FileAccess]::Read)
              $guest_md5 = ([System.BitConverter]::ToString($crypto_provider.ComputeHash($file))).Replace("-","").ToLower()
            }
            finally {
              $file.Dispose()
            }
            if ($guest_md5 -eq '#{local_md5}') {
              exit 0
            }
          }
          Write-Host "should upload file $dest_file_path"
          exit 1
        EOH
        @shell.powershell(cmd)[:exitcode] == 1
      end

      # Creates a guest file path equivalent from a host file path
      #
      # @param [String] The base host directory we're going to copy from
      # @param [String] The base guest directory we're going to copy to
      # @param [String] A full path to a file on the host underneath host_base_dir
      # @return [String] The guest file path equivalent
      def guest_file_path(host_base_dir, guest_base_dir, host_file_path)
        rel_path = File.dirname(host_file_path[host_base_dir.length, host_file_path.length])
        File.join(guest_base_dir, rel_path, File.basename(host_file_path))
      end

      def guest_temp_dir
        @guest_temp ||= (@shell.cmd('echo %TEMP%'))[:data][0][:stdout].chomp
      end

      def raise_upload_error_if_failed(out, from, to)
        raise Errors::WinRMFileTransferError,
          from: from,
          to: to,
          message: out.inspect if out[:exitcode] != 0
      end
    end
  end
end
