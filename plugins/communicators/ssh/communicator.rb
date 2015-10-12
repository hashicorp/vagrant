require 'logger'
require 'pathname'
require 'stringio'
require 'thread'
require 'timeout'

require 'log4r'
require 'net/ssh'
require 'net/ssh/proxy/command'
require 'net/scp'

require 'vagrant/util/ansi_escape_code_remover'
require 'vagrant/util/file_mode'
require 'vagrant/util/keypair'
require 'vagrant/util/platform'
require 'vagrant/util/retryable'

module VagrantPlugins
  module CommunicatorSSH
    # This class provides communication with the VM via SSH.
    class Communicator < Vagrant.plugin("2", :communicator)
      PTY_DELIM_START = "bccbb768c119429488cfd109aacea6b5-pty"
      PTY_DELIM_END = "bccbb768c119429488cfd109aacea6b5-pty"

      include Vagrant::Util::ANSIEscapeCodeRemover
      include Vagrant::Util::Retryable

      def self.match?(machine)
        # All machines are currently expected to have SSH.
        true
      end

      def initialize(machine)
        @lock    = Mutex.new
        @machine = machine
        @logger  = Log4r::Logger.new("vagrant::communication::ssh")
        @connection = nil
        @inserted_key = false
      end

      def wait_for_ready(timeout)
        Timeout.timeout(timeout) do
          # Wait for ssh_info to be ready
          ssh_info = nil
          while true
            ssh_info = @machine.ssh_info
            break if ssh_info
            sleep 0.5
          end

          # Got it! Let the user know what we're connecting to.
          @machine.ui.detail("SSH address: #{ssh_info[:host]}:#{ssh_info[:port]}")
          @machine.ui.detail("SSH username: #{ssh_info[:username]}")
          ssh_auth_type = "private key"
          ssh_auth_type = "password" if ssh_info[:password]
          @machine.ui.detail("SSH auth method: #{ssh_auth_type}")

          last_message = nil
          last_message_repeat_at = 0
          while true
            message  = nil
            begin
              begin
                connect(retries: 1)
                return true if ready?
              rescue Vagrant::Errors::VagrantError => e
                @logger.info("SSH not ready: #{e.inspect}")
                raise
              end
            rescue Vagrant::Errors::SSHConnectionTimeout
              message = "Connection timeout."
            rescue Vagrant::Errors::SSHAuthenticationFailed
              message = "Authentication failure."
            rescue Vagrant::Errors::SSHDisconnected
              message = "Remote connection disconnect."
            rescue Vagrant::Errors::SSHConnectionRefused
              message = "Connection refused."
            rescue Vagrant::Errors::SSHConnectionReset
              message = "Connection reset."
            rescue Vagrant::Errors::SSHHostDown
              message = "Host appears down."
            rescue Vagrant::Errors::SSHNoRoute
              message = "Host unreachable."
            rescue Vagrant::Errors::SSHInvalidShell
              raise
            rescue Vagrant::Errors::SSHKeyTypeNotSupported
              raise
            rescue Vagrant::Errors::SSHKeyBadOwner
              raise
            rescue Vagrant::Errors::SSHKeyBadPermissions
              raise
            rescue Vagrant::Errors::SSHInsertKeyUnsupported
              raise
            rescue Vagrant::Errors::VagrantError => e
              # Ignore it, SSH is not ready, some other error.
            end

            # If we have a message to show, then show it. We don't show
            # repeated messages unless they've been repeating longer than
            # 10 seconds.
            if message
              message_at   = Time.now.to_f
              show_message = true
              if last_message == message
                show_message = (message_at - last_message_repeat_at) > 10.0
              end

              if show_message
                @machine.ui.detail("Warning: #{message} Retrying...")
                last_message = message
                last_message_repeat_at = message_at
              end
            end
          end
        end
      rescue Timeout::Error
        return false
      end

      def ready?
        @logger.debug("Checking whether SSH is ready...")

        # Attempt to connect. This will raise an exception if it fails.
        begin
          connect
          @logger.info("SSH is ready!")
        rescue Vagrant::Errors::VagrantError => e
          # We catch a `VagrantError` which would signal that something went
          # wrong expectedly in the `connect`, which means we didn't connect.
          @logger.info("SSH not up: #{e.inspect}")
          return false
        end

        # Verify the shell is valid
        if execute("", error_check: false) != 0
          raise Vagrant::Errors::SSHInvalidShell
        end

        # If we're already attempting to switch out the SSH key, then
        # just return that we're ready (for Machine#guest).
        @lock.synchronize do
          return true if @inserted_key || !@machine.config.ssh.insert_key
          @inserted_key = true
        end

        # If we used a password, then insert the insecure key
        ssh_info = @machine.ssh_info
        insert   = ssh_info[:password] && ssh_info[:private_key_path].empty?
        ssh_info[:private_key_path].each do |pk|
          if insecure_key?(pk)
            insert = true
            @machine.ui.detail("\n"+I18n.t("vagrant.inserting_insecure_detected"))
            break
          end
        end

        if insert
          # If we don't have the power to insert/remove keys, then its an error
          cap = @machine.guest.capability?(:insert_public_key) &&
            @machine.guest.capability?(:remove_public_key)
          raise Vagrant::Errors::SSHInsertKeyUnsupported if !cap

          _pub, priv, openssh = Vagrant::Util::Keypair.create

          @logger.info("Inserting key to avoid password: #{openssh}")
          @machine.ui.detail("\n"+I18n.t("vagrant.inserting_random_key"))
          @machine.guest.capability(:insert_public_key, openssh)

          # Write out the private key in the data dir so that the
          # machine automatically picks it up.
          @machine.data_dir.join("private_key").open("w+") do |f|
            f.write(priv)
          end

          # Remove the old key if it exists
          @machine.ui.detail(I18n.t("vagrant.inserting_remove_key"))
          @machine.guest.capability(
            :remove_public_key,
            Vagrant.source_root.join("keys", "vagrant.pub").read.chomp)

          # Done, restart.
          @machine.ui.detail(I18n.t("vagrant.inserted_key"))
          @connection.close
          @connection = nil

          return ready?
        end

        # If we reached this point then we successfully connected
        true
      end

      def execute(command, opts=nil, &block)
        opts = {
          error_check: true,
          error_class: Vagrant::Errors::VagrantError,
          error_key:   :ssh_bad_exit_status,
          good_exit:   0,
          command:     command,
          shell:       nil,
          sudo:        false,
        }.merge(opts || {})

        opts[:good_exit] = Array(opts[:good_exit])

        # Connect via SSH and execute the command in the shell.
        stdout = ""
        stderr = ""
        exit_status = connect do |connection|
          shell_opts = {
            sudo: opts[:sudo],
            shell: opts[:shell],
          }

          shell_execute(connection, command, **shell_opts) do |type, data|
            if type == :stdout
              stdout += data
            elsif type == :stderr
              stderr += data
            end

            block.call(type, data) if block
          end
        end

        # Check for any errors
        if opts[:error_check] && !opts[:good_exit].include?(exit_status)
          # The error classes expect the translation key to be _key,
          # but that makes for an ugly configuration parameter, so we
          # set it here from `error_key`
          error_opts = opts.merge(
            _key: opts[:error_key],
            stdout: stdout,
            stderr: stderr
          )
          raise opts[:error_class], error_opts
        end

        # Return the exit status
        exit_status
      end

      def sudo(command, opts=nil, &block)
        # Run `execute` but with the `sudo` option.
        opts = { sudo: true }.merge(opts || {})
        execute(command, opts, &block)
      end

      def download(from, to=nil)
        @logger.debug("Downloading: #{from} to #{to}")

        scp_connect do |scp|
          scp.download!(from, to)
        end
      end

      def test(command, opts=nil)
        opts = { error_check: false }.merge(opts || {})
        execute(command, opts) == 0
      end

      def upload(from, to)
        @logger.debug("Uploading: #{from} to #{to}")

        scp_connect do |scp|
          if File.directory?(from)
            # Recurisvely upload directories
            scp.upload!(from, to, recursive: true)
          else
            # Open file read only to fix issue [GH-1036]
            scp.upload!(File.open(from, "r"), to)
          end
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

      protected

      # Opens an SSH connection and yields it to a block.
      def connect(**opts)
        if @connection && !@connection.closed?
          # There is a chance that the socket is closed despite us checking
          # 'closed?' above. To test this we need to send data through the
          # socket.
          #
          # We wrap the check itself in a 5 second timeout because there
          # are some cases where this will just hang.
          begin
            Timeout.timeout(5) do
              @connection.exec!("")
            end
          rescue Exception => e
            @logger.info("Connection errored, not re-using. Will reconnect.")
            @logger.debug(e.inspect)
            @connection = nil
          end

          # If the @connection is still around, then it is valid,
          # and we use it.
          if @connection
            @logger.debug("Re-using SSH connection.")
            return yield @connection if block_given?
            return
          end
        end

        # Get the SSH info for the machine, raise an exception if the
        # provider is saying that SSH is not ready.
        ssh_info = @machine.ssh_info
        raise Vagrant::Errors::SSHNotReady if ssh_info.nil?

        # Default some options
        opts[:retries] = 5 if !opts.key?(:retries)

        # Set some valid auth methods. We disable the auth methods that
        # we're not using if we don't have the right auth info.
        auth_methods = ["none", "hostbased"]
        auth_methods << "publickey" if ssh_info[:private_key_path]
        auth_methods << "password" if ssh_info[:password]

        # Build the options we'll use to initiate the connection via Net::SSH
        common_connect_opts = {
          auth_methods:          auth_methods,
          config:                false,
          forward_agent:         ssh_info[:forward_agent],
          keys:                  ssh_info[:private_key_path],
          keys_only:             true,
          paranoid:              false,
          password:              ssh_info[:password],
          port:                  ssh_info[:port],
          timeout:               15,
          user_known_hosts_file: [],
          verbose:               :debug,
        }

        # Connect to SSH, giving it a few tries
        connection = nil
        begin
          # These are the exceptions that we retry because they represent
          # errors that are generally fixed from a retry and don't
          # necessarily represent immediate failure cases.
          exceptions = [
            Errno::EACCES,
            Errno::EADDRINUSE,
            Errno::ECONNREFUSED,
            Errno::ECONNRESET,
            Errno::ENETUNREACH,
            Errno::EHOSTUNREACH,
            Net::SSH::Disconnect,
            Timeout::Error
          ]

          timeout = 60

          @logger.info("Attempting SSH connection...")
          connection = retryable(tries: opts[:retries], on: exceptions) do
            Timeout.timeout(timeout) do
              begin
                # This logger will get the Net-SSH log data for us.
                ssh_logger_io = StringIO.new
                ssh_logger    = Logger.new(ssh_logger_io)

                # Setup logging for connections
                connect_opts = common_connect_opts.dup
                connect_opts[:logger] = ssh_logger

                if ssh_info[:proxy_command]
                  connect_opts[:proxy] = Net::SSH::Proxy::Command.new(ssh_info[:proxy_command])
                end

                @logger.info("Attempting to connect to SSH...")
                @logger.info("  - Host: #{ssh_info[:host]}")
                @logger.info("  - Port: #{ssh_info[:port]}")
                @logger.info("  - Username: #{ssh_info[:username]}")
                @logger.info("  - Password? #{!!ssh_info[:password]}")
                @logger.info("  - Key Path: #{ssh_info[:private_key_path]}")

                Net::SSH.start(ssh_info[:host], ssh_info[:username], connect_opts)
              ensure
                # Make sure we output the connection log
                @logger.debug("== Net-SSH connection debug-level log START ==")
                @logger.debug(ssh_logger_io.string)
                @logger.debug("== Net-SSH connection debug-level log END ==")
              end
            end
          end
        rescue Errno::EACCES
          # This happens on connect() for unknown reasons yet...
          raise Vagrant::Errors::SSHConnectEACCES
        rescue Errno::ETIMEDOUT, Timeout::Error
          # This happens if we continued to timeout when attempting to connect.
          raise Vagrant::Errors::SSHConnectionTimeout
        rescue Net::SSH::AuthenticationFailed
          # This happens if authentication failed. We wrap the error in our
          # own exception.
          raise Vagrant::Errors::SSHAuthenticationFailed
        rescue Net::SSH::Disconnect
          # This happens if the remote server unexpectedly closes the
          # connection. This is usually raised when SSH is running on the
          # other side but can't properly setup a connection. This is
          # usually a server-side issue.
          raise Vagrant::Errors::SSHDisconnected
        rescue Errno::ECONNREFUSED
          # This is raised if we failed to connect the max amount of times
          raise Vagrant::Errors::SSHConnectionRefused
        rescue Errno::ECONNRESET
          # This is raised if we failed to connect the max number of times
          # due to an ECONNRESET.
          raise Vagrant::Errors::SSHConnectionReset
        rescue Errno::EHOSTDOWN
          # This is raised if we get an ICMP DestinationUnknown error.
          raise Vagrant::Errors::SSHHostDown
        rescue Errno::EHOSTUNREACH
          # This is raised if we can't work out how to route traffic.
          raise Vagrant::Errors::SSHNoRoute
        rescue Net::SSH::Exception => e
          # This is an internal error in Net::SSH
          raise Vagrant::Errors::NetSSHException, message: e.message
        rescue NotImplementedError
          # This is raised if a private key type that Net-SSH doesn't support
          # is used. Show a nicer error.
          raise Vagrant::Errors::SSHKeyTypeNotSupported
        end

        @connection          = connection
        @connection_ssh_info = ssh_info

        # Yield the connection that is ready to be used and
        # return the value of the block
        return yield connection if block_given?
      end

      # The shell wrapper command used in shell_execute defined by
      # the sudo and shell options.
      def shell_cmd(opts)
        sudo  = opts[:sudo]
        shell = opts[:shell]

        # Determine the shell to execute. Prefer the explicitly passed in shell
        # over the default configured shell. If we are using `sudo` then we
        # need to wrap the shell in a `sudo` call.
        cmd = @machine.config.ssh.shell
        cmd = shell if shell
        cmd = @machine.config.ssh.sudo_command.gsub("%c", cmd) if sudo
        cmd
      end

      # Executes the command on an SSH connection within a login shell.
      def shell_execute(connection, command, **opts)
        opts = {
          sudo: false,
          shell: nil
        }.merge(opts)

        sudo  = opts[:sudo]

        @logger.info("Execute: #{command} (sudo=#{sudo.inspect})")
        exit_status = nil

        # These variables are used to scrub PTY output if we're in a PTY
        pty = false
        pty_stdout = ""

        # Open the channel so we can execute or command
        channel = connection.open_channel do |ch|
          if @machine.config.ssh.pty
            ch.request_pty do |ch2, success|
              pty = success && command != ""

              if success
                @logger.debug("pty obtained for connection")
              else
                @logger.warn("failed to obtain pty, will try to continue anyways")
              end
            end
          end

          ch.exec(shell_cmd(opts)) do |ch2, _|
            # Setup the channel callbacks so we can get data and exit status
            ch2.on_data do |ch3, data|
              # Filter out the clear screen command
              data = remove_ansi_escape_codes(data)
              @logger.debug("stdout: #{data}")
              if pty
                pty_stdout << data
              else
                yield :stdout, data if block_given?
              end
            end

            ch2.on_extended_data do |ch3, type, data|
              # Filter out the clear screen command
              data = remove_ansi_escape_codes(data)
              @logger.debug("stderr: #{data}")
              yield :stderr, data if block_given?
            end

            ch2.on_request("exit-status") do |ch3, data|
              exit_status = data.read_long
              @logger.debug("Exit status: #{exit_status}")

              # Close the channel, since after the exit status we're
              # probably done. This fixes up issues with hanging.
              channel.close
            end

            # Set the terminal
            ch2.send_data "export TERM=vt100\n"

            # Set SSH_AUTH_SOCK if we are in sudo and forwarding agent.
            # This is to work around often misconfigured boxes where
            # the SSH_AUTH_SOCK env var is not preserved.
            if @connection_ssh_info[:forward_agent] && sudo
              auth_socket = ""
              execute("echo; printf $SSH_AUTH_SOCK") do |type, data|
                if type == :stdout
                  auth_socket += data
                end
              end

              if auth_socket != ""
                # Make sure we only read the last line which should be
                # the $SSH_AUTH_SOCK env var we printed.
                auth_socket = auth_socket.split("\n").last.chomp
              end

              if auth_socket == ""
                @logger.warn("No SSH_AUTH_SOCK found despite forward_agent being set.")
              else
                @logger.info("Setting SSH_AUTH_SOCK remotely: #{auth_socket}")
                ch2.send_data "export SSH_AUTH_SOCK=#{auth_socket}\n"
              end
            end

            # Output the command. If we're using a pty we have to do
            # a little dance to make sure we get all the output properly
            # without the cruft added from pty mode.
            if pty
              data = "stty raw -echo\n"
              data += "export PS1=\n"
              data += "export PS2=\n"
              data += "export PROMPT_COMMAND=\n"
              data += "printf #{PTY_DELIM_START}\n"
              data += "#{command}\n"
              data += "exitcode=$?\n"
              data += "printf #{PTY_DELIM_END}\n"
              data += "exit $exitcode\n"
              data = data.force_encoding('ASCII-8BIT')
              ch2.send_data data
            else
              ch2.send_data "#{command}\n".force_encoding('ASCII-8BIT')
              # Remember to exit or this channel will hang open
              ch2.send_data "exit\n"
            end

            # Send eof to let server know we're done
            ch2.eof!
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

        # If we're in a PTY, we now finally parse the output
        if pty
          @logger.debug("PTY stdout: #{pty_stdout}")
          if !pty_stdout.include?(PTY_DELIM_START) || !pty_stdout.include?(PTY_DELIM_END)
            @logger.error("PTY stdout doesn't include delims")
            raise Vagrant::Errors::SSHInvalidShell.new
          end

          data = pty_stdout[/.*#{PTY_DELIM_START}(.*?)#{PTY_DELIM_END}/m, 1]
          @logger.debug("PTY stdout parsed: #{data}")
          yield :stdout, data if block_given?
        end

        # Return the final exit status
        return exit_status
      end

      # Opens an SCP connection and yields it so that you can download
      # and upload files.
      def scp_connect
        # Connect to SCP and yield the SCP object
        connect do |connection|
          scp = Net::SCP.new(connection)
          return yield scp
        end
      rescue Net::SCP::Error => e
        # If we get the exit code of 127, then this means SCP is unavailable.
        raise Vagrant::Errors::SCPUnavailable if e.message =~ /\(127\)/

        # Otherwise, just raise the error up
        raise
      end

      # This will test whether path is the Vagrant insecure private key.
      #
      # @param [String] path
      def insecure_key?(path)
        return false if !path
        return false if !File.file?(path)
        source_path = Vagrant.source_root.join("keys", "vagrant")
        return File.read(path).chomp == source_path.read.chomp
      end
    end
  end
end
