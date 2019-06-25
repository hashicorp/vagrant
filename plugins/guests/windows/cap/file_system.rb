require 'json'

module VagrantPlugins
  module GuestWindows
    module Cap
      class FileSystem
        # Create a temporary file or directory on the guest
        #
        # @param [Vagrant::Machine] machine Vagrant guest machine
        # @param [Hash] opts Path options
        # @return [String] path to temporary file or directory
        def self.create_tmp_path(machine, opts)
          comm = machine.communicate
          path = ""
          cmd = "Write-Output ([System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), " \
            "[System.IO.Path]::GetRandomFileName())) | Out-String -Width 2048"
          comm.execute(cmd, shell: :powershell) do |type, data|
            if type == :stdout
              path << data
            end
          end
          path.strip!
          if opts[:extension]
            path << opts[:extension].to_s
          end
          if opts[:type] == :directory
            comm.execute("[System.IO.Directory]::CreateDirectory('#{path}')")
          end
          path
        end

        # Decompress zip file on guest to given location
        #
        # @param [Vagrant::Machine] machine Vagrant guest machine
        # @param [String] compressed_file Path to compressed file on guest
        # @param [String] destination Path for decompressed files on guest
        def self.decompress_zip(machine, compressed_file, destination, opts={})
          comm = machine.communicate
          extract_dir = create_tmp_path(machine, type: :directory)
          cmds = []
          destination = destination.tr("/", "\\")
          if opts[:type] == :directory
            cmds << "New-Item -ItemType Directory -Force -Path \"#{destination}\""
          else
            d_parts = destination.split("\\")
            d_parts.pop
            parent_dir = d_parts.join("\\") + "\\"
            cmds << "New-Item -ItemType Directory -Force -Path \"#{parent_dir}\""
          end
          cmd = "$f = \"#{compressed_file}\"; $d = \"#{extract_dir}\"; "
          cmd << '$s = New-Object -ComObject "Shell.Application"; $z = $s.NameSpace($f); '
          cmd << 'foreach($i in $z.items()){ $s.Namespace($d).copyhere($i); }'
          cmds << cmd
          cmds += [
            "Move-Item -Force -Path \"#{extract_dir}\\*\" -Destination \"#{destination}\\\"",
            "Remove-Item -Path \"#{compressed_file}\" -Force",
            "Remove-Item -Path \"#{extract_dir}\" -Recurse -Force"
          ]
          cmds.each do |cmd|
            comm.execute(cmd, shell: :powershell)
          end
          true
        end

        # Create directories at given locations on guest
        #
        # @param [Vagrant::Machine] machine Vagrant guest machine
        # @param [array] paths to create on guest
        def self.create_directories(machine, dirs, opts={})
          return [] if dirs.empty?

          remote_fn = create_tmp_path(machine, {})
          tmp = Tempfile.new('hv_dirs')
          begin
            tmp.write dirs.join("\n") + "\n"
            tmp.close
            machine.communicate.upload(tmp.path, remote_fn)
          ensure
            tmp.close
            tmp.unlink
          end
          created_paths = []
          cmd = <<-EOH.gsub(/^ {6}/, "")
      $files = Get-Content #{remote_fn}
      foreach ($file in $files) {
        if (-Not (Test-Path($file))) {
          ConvertTo-Json (New-Item $file -type directory -Force | Select-Object FullName)
        } else {
          if (-Not ((Get-Item $file) -is [System.IO.DirectoryInfo])) {
            # Remove the file
            Remove-Item -Path $file -Force
            ConvertTo-Json (New-Item $file -type directory -Force | Select-Object FullName)
          }
        }
      }
          EOH
          machine.communicate.execute(cmd, shell: :powershell) do |type, data|
            if type == :stdout
              obj = JSON.parse(data)
              created_paths << obj["FullName"].strip unless obj["FullName"].nil?
            end
          end
          created_paths
        end
      end
    end
  end
end
