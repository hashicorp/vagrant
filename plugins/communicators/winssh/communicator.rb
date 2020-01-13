require File.expand_path("../../ssh/communicator", __FILE__)

module VagrantPlugins
  module CommunicatorWinSSH
    # This class provides communication with a Windows VM running
    # the Windows native port of OpenSSH
    class Communicator < VagrantPlugins::CommunicatorSSH::Communicator

      def initialize(machine)
        super
        @logger = Log4r::Logger.new("vagrant::communication::winssh")
      end

      # Executes the command on an SSH connection within a login shell.
      def shell_execute(connection, command, **opts)
        opts = {
          sudo: false,
          shell: nil,
          force_raw: false
        }.merge(opts)

        sudo      = opts[:sudo]
        shell     = (opts[:shell] || machine_config_ssh.shell).to_s
        force_raw = opts[:force_raw]

        @logger.info("Execute: #{command} (sudo=#{sudo.inspect})")
        exit_status = nil

        # Open the channel so we can execute or command
        channel = connection.open_channel do |ch|
          marker_found = false
          data_buffer = ''
          stderr_marker_found = false
          stderr_data_buffer = ''

          if force_raw
            base_cmd = "cmd /Q /C #{command}"
          else
            tfile = Tempfile.new('vagrant-ssh')
            remote_ext = shell == "powershell" ? "ps1" : "bat"
            remote_name = "#{machine_config_ssh.upload_directory}\\#{File.basename(tfile.path)}.#{remote_ext}"

            if shell == "powershell"
              base_cmd = "powershell -File #{remote_name}"
              tfile.puts <<-SCRIPT.force_encoding('ASCII-8BIT')
Remove-Item #{remote_name}
Write-Host #{CMD_GARBAGE_MARKER}
[Console]::Error.WriteLine("#{CMD_GARBAGE_MARKER}")
#{command}
SCRIPT
            else
              base_cmd = remote_name
              tfile.puts <<-SCRIPT.force_encoding('ASCII-8BIT')
ECHO OFF
ECHO #{CMD_GARBAGE_MARKER}
ECHO #{CMD_GARBAGE_MARKER} 1>&2
#{command}
SCRIPT
            end

            tfile.close
            upload(tfile.path, remote_name)
            tfile.delete

            base_cmd = shell_cmd(opts.merge(shell: base_cmd))
          end

          @logger.debug("Base SSH exec command: #{base_cmd}")

          ch.exec(base_cmd) do |ch2, _|
            # Setup the channel callbacks so we can get data and exit status
            ch2.on_data do |ch3, data|
              # Filter out the clear screen command
              data = remove_ansi_escape_codes(data)

              if !marker_found
                data_buffer << data
                marker_index = data_buffer.index(CMD_GARBAGE_MARKER)
                if marker_index
                  marker_found = true
                  data_buffer.slice!(0, marker_index + CMD_GARBAGE_MARKER.size)
                  data.replace(data_buffer)
                  data_buffer = nil
                end
              end

              if block_given? && marker_found
                yield :stdout, data
              end
            end

            ch2.on_extended_data do |ch3, type, data|
              # Filter out the clear screen command
              data = remove_ansi_escape_codes(data)
              @logger.debug("stderr: #{data}")
              if !stderr_marker_found
                stderr_data_buffer << data
                marker_index = stderr_data_buffer.index(CMD_GARBAGE_MARKER)
                if marker_index
                  marker_found = true
                  stderr_data_buffer.slice!(0, marker_index + CMD_GARBAGE_MARKER.size)
                  data.replace(stderr_data_buffer.lstrip)
                  data_buffer = nil
                end
              end

              if block_given? && marker_found
                yield :stderr, data
              end
            end

            ch2.on_request("exit-status") do |ch3, data|
              exit_status = data.read_long
              @logger.debug("Exit status: #{exit_status}")

              # Close the channel, since after the exit status we're
              # probably done. This fixes up issues with hanging.
              ch.close
            end

          end
        end

        begin
          keep_alive = nil

          if @machine.config.ssh.keep_alive
            # Begin sending keep-alive packets while we wait for the script
            # to complete. This avoids connections closing on long-running
            # scripts.
            keep_alive = Thread.new do
              loop do
                sleep 5
                @logger.debug("Sending SSH keep-alive...")
                connection.send_global_request("keep-alive@openssh.com")
              end
            end
          end

          # Wait for the channel to complete
          begin
            channel.wait
          rescue Errno::ECONNRESET, IOError
            @logger.info(
              "SSH connection unexpected closed. Assuming reboot or something.")
            exit_status = 0
            pty = false
          rescue Net::SSH::ChannelOpenFailed
            raise Vagrant::Errors::SSHChannelOpenFail
          rescue Net::SSH::Disconnect
            raise Vagrant::Errors::SSHDisconnected
          end
        ensure
          # Kill the keep-alive thread
          keep_alive.kill if keep_alive
        end

        # Return the final exit status
        return exit_status
      end

      def machine_config_ssh
        @machine.config.winssh
      end

      def upload(from, to)
        to = Vagrant::Util::Platform.unix_windows_path(to)
        @logger.debug("Uploading: #{from} to #{to}")

        if File.directory?(from)
          if from.end_with?(".")
            @logger.debug("Uploading directory contents of: #{from}")
            from = from.sub(/\.$/, "")
          else
            @logger.debug("Uploading full directory container of: #{from}")
            to = File.join(to, File.basename(File.expand_path(from)))
          end
        end

        scp_connect do |scp|
          uploader = lambda do |path, remote_dest=nil|
            if File.directory?(path)
              Dir.new(path).each do |entry|
                next if entry == "." || entry == ".."
                full_path = File.join(path, entry)
                dest = File.join(to, path.sub(/^#{Regexp.escape(from)}/, ""))
                create_remote_directory(dest)
                uploader.call(full_path, dest)
              end
            else
              if remote_dest
                dest = File.join(remote_dest, File.basename(path))
              else
                dest = to
                if to.end_with?(File::SEPARATOR)
                  dest = File.join(to, File.basename(path))
                end
              end
              @logger.debug("Ensuring remote directory exists for destination upload")
              create_remote_directory(File.dirname(dest))
              @logger.debug("Uploading file #{path} to remote #{dest}")
              upload_file = File.open(path, "rb")
              begin
                scp.upload!(upload_file, dest)
              ensure
                upload_file.close
              end
            end
          end
          uploader.call(from)
        end
      rescue RuntimeError => e
        # Net::SCP raises a runtime error for this so the only way we have
        # to really catch this exception is to check the message to see if
        # it is something we care about. If it isn't, we re-raise.
        raise if e.message !~ /Permission denied/

        # Otherwise, it is a permission denied, so let's raise a proper
        # exception
        raise Vagrant::Errors::SCPPermissionDenied,
          from: from.to_s,
          to: to.to_s
      end

      def create_remote_directory(dir, force_raw=false)
        execute("dir \"#{dir}\"\n if errorlevel 1 (mkdir \"#{dir}\")", shell: "cmd", force_raw: force_raw)
      end
    end
  end
end
