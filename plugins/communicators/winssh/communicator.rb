require File.expand_path("../../ssh/communicator", __FILE__)

require 'net/sftp'

module VagrantPlugins
  module CommunicatorWinSSH
    # This class provides communication with a Windows VM running
    # the Windows native port of OpenSSH
    class Communicator < VagrantPlugins::CommunicatorSSH::Communicator
      # Command to run when checking if connection is ready and working
      READY_COMMAND="dir"

      def initialize(machine)
        super
        @logger = Log4r::Logger.new("vagrant::communication::winssh")
      end

      # Wrap the shell if required. By default we are using powershell
      # which requires no modification. If cmd is defined as shell, add
      # prefix to start within cmd.exe
      def shell_cmd(opts)
        case opts[:shell].to_s
        when "cmd"
          "cmd.exe /c '#{opts[:command]}'"
        else
          opts[:command]
        end
      end

      # Executes the command on an SSH connection within a login shell.
      def shell_execute(connection, command, **opts)
        opts[:shell] ||= machine_config_ssh.shell

        command = shell_cmd(opts.merge(command: command))

        @logger.info("Execute: #{command} - opts: #{opts}")
        exit_status = nil

        # Open the channel so we can execute or command
        channel = connection.open_channel do |ch|
          marker_found = false
          data_buffer = ''
          stderr_marker_found = false
          stderr_data_buffer = ''

          @logger.debug("Base SSH exec command: #{command}")
          command = "$ProgressPreference = 'SilentlyContinue';Write-Output #{CMD_GARBAGE_MARKER};[Console]::Error.WriteLine('#{CMD_GARBAGE_MARKER}');#{command}"

          ch.exec(command) do |ch2, _|
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
                  stderr_marker_found = true
                  stderr_data_buffer.slice!(0, marker_index + CMD_GARBAGE_MARKER.size)
                  data.replace(stderr_data_buffer.lstrip)
                  data_buffer = nil
                end
              end

              if block_given? && stderr_marker_found && !data.empty?
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

      def download(from, to=nil)
        @logger.debug("Downloading: #{from} to #{to}")

        sftp_connect do |sftp|
          sftp.download!(from, to)
        end
      end

      # Note: I could not get Net::SFTP to throw a permissions denied error,
      # even when uploading to a directory where I did not have write
      # privileges. I believe this is because Windows SSH sessions are started
      # in an elevated process.
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

        sftp_connect do |sftp|
          uploader = lambda do |path, remote_dest=nil|
            if File.directory?(path)
              Dir.new(path).each do |entry|
                next if entry == "." || entry == ".."
                full_path = File.join(path, entry)
                dest = File.join(to, path.sub(/^#{Regexp.escape(from)}/, ""))
                sftp.mkdir(dest)
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
              sftp.mkdir(File.dirname(dest))
              @logger.debug("Uploading file #{path} to remote #{dest}")
              upload_file = File.open(path, "rb")
              begin
                sftp.upload!(upload_file, dest)
              ensure
                upload_file.close
              end
            end
          end
          uploader.call(from)
        end
      end

      # Opens an SFTP connection and yields it so that you can download and
      # upload files. SFTP works more reliably than SCP on Windows due to
      # issues with shell quoting and escaping.
      def sftp_connect
        # Connect to SFTP and yield the SFTP object
        connect do |connection|
          return yield connection.sftp
        end
      end

      protected

      # The WinSSH communicator connection provides isolated modification
      # to the generated connection instances. This modification forces
      # all provided commands to run within powershell
      def connect(**opts)
        connection = nil
        super { |c| connection = c }

        if !connection.instance_variable_get(:@winssh_patched)
          open_chan = connection.method(:open_channel)
          connection.define_singleton_method(:open_channel) do |*args, &chan_block|
            open_chan.call(*args) do |ch|
              exec = ch.method(:exec)
              ch.define_singleton_method(:exec) do |command, &block|
                command = Base64.strict_encode64(command.encode("UTF-16LE", "UTF-8"))
                command = "powershell -NoLogo -NonInteractive -ExecutionPolicy Bypass " \
                  "-NoProfile -EncodedCommand #{command}"
                exec.call(command, &block)
              end
              chan_block.call(ch)
            end
          end
          connection.instance_variable_set(:@winssh_patched, true)
        end

        if block_given?
          yield connection
        else
          connection
        end
      end
    end
  end
end
