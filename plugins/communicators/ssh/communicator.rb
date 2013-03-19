require 'logger'
require 'pathname'
require 'stringio'
require 'timeout'

require 'log4r'
require 'net/ssh'
require 'net/scp'

require 'vagrant/util/ansi_escape_code_remover'
require 'vagrant/util/file_mode'
require 'vagrant/util/platform'
require 'vagrant/util/retryable'
require 'vagrant/util/ssh'

module VagrantPlugins
  module CommunicatorSSH
    # This class provides communication with the VM via SSH.
    class Communicator < Vagrant.plugin("2", :communicator)
      include Vagrant::Util::ANSIEscapeCodeRemover
      include Vagrant::Util::Retryable

      def self.match?(machine)
        # All machines are currently expected to have SSH.
        true
      end

      def initialize(machine)
        @machine = machine
        @logger  = Log4r::Logger.new("vagrant::communication::ssh")
        @connection = nil
      end

      def ready?
        @logger.debug("Checking whether SSH is ready...")

        # Attempt to connect. This will raise an exception if it fails.
        connect

        # If we reached this point then we successfully connected
        @logger.info("SSH is ready!")
        true
      rescue Vagrant::Errors::VagrantError => e
        # We catch a `VagrantError` which would signal that something went
        # wrong expectedly in the `connect`, which means we didn't connect.
        @logger.info("SSH not up: #{e.inspect}")
        return false
      end

      def execute(command, opts=nil, &block)
        opts = {
          :error_check => true,
          :error_class => Vagrant::Errors::VagrantError,
          :error_key   => :ssh_bad_exit_status,
          :command     => command,
          :sudo        => false
        }.merge(opts || {})

        # Connect via SSH and execute the command in the shell.
        exit_status = connect do |connection|
          shell_execute(connection, command, opts[:sudo], &block)
        end

        # Check for any errors
        if opts[:error_check] && exit_status != 0
          # The error classes expect the translation key to be _key,
          # but that makes for an ugly configuration parameter, so we
          # set it here from `error_key`
          error_opts = opts.merge(:_key => opts[:error_key])
          raise opts[:error_class], error_opts
        end

        # Return the exit status
        exit_status
      end

      def sudo(command, opts=nil, &block)
        # Run `execute` but with the `sudo` option.
        opts = { :sudo => true }.merge(opts || {})
        execute(command, opts, &block)
      end

      def download(from, to=nil)
        @logger.debug("Downloading: #{from} to #{to}")

        scp_connect do |scp|
          scp.download!(from, to)
        end
      end

      def test(command, opts=nil)
        opts = { :error_check => false }.merge(opts || {})
        execute(command, opts) == 0
      end

      def upload(from, to)
        @logger.debug("Uploading: #{from} to #{to}")

        scp_connect do |scp|
          if File.directory?(from)
            # Recurisvely upload directories
            scp.upload!(from, to, :recursive => true)
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
        raise Vagrant::Errors::SCPPermissionDenied, :path => from.to_s
      end

      protected

      # Opens an SSH connection and yields it to a block.
      def connect
        if @connection && !@connection.closed?
          # There is a chance that the socket is closed despite us checking
          # 'closed?' above. To test this we need to send data through the
          # socket.
          begin
            @connection.exec!("")
          rescue Errno::EHOSTUNREACH
            @logger.info("No route to host for connection. Not re-using.")
            @connection = nil
          rescue Net::SSH::Disconnect
            @logger.info("SSH disconnected. Not-reusing connection.")
            @connection = nil
          rescue IOError
            @logger.info("Connection has been closed. Not re-using.")
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

        # Build the options we'll use to initiate the connection via Net::SSH
        opts = {
          :auth_methods          => ["none", "publickey", "hostbased", "password"],
          :config                => false,
          :forward_agent         => ssh_info[:forward_agent],
          :keys                  => [ssh_info[:private_key_path]],
          :keys_only             => true,
          :paranoid              => false,
          :port                  => ssh_info[:port],
          :user_known_hosts_file => []
        }

        # Check that the private key permissions are valid
        Vagrant::Util::SSH.check_key_permissions(Pathname.new(ssh_info[:private_key_path]))

        # Connect to SSH, giving it a few tries
        connection = nil
        begin
          # These are the exceptions that we retry because they represent
          # errors that are generally fixed from a retry and don't
          # necessarily represent immediate failure cases.
          exceptions = [
            Errno::EADDRINUSE,
            Errno::ECONNREFUSED,
            Errno::ECONNRESET,
            Errno::EHOSTUNREACH,
            Net::SSH::Disconnect,
            Timeout::Error
          ]

          retries = @machine.config.ssh.max_tries
          timeout = @machine.config.ssh.timeout

          @logger.info("Attempting SSH. Retries: #{retries}. Timeout: #{timeout}")
          connection = retryable(:tries => retries, :on => exceptions) do
            Timeout.timeout(timeout) do
              begin
                # This logger will get the Net-SSH log data for us.
                ssh_logger_io = StringIO.new
                ssh_logger    = Logger.new(ssh_logger_io)

                # Setup logging for connections
                connect_opts = opts.merge({
                  :logger  => ssh_logger,
                  :verbose => :debug
                })

                @logger.info("Attempting to connect to SSH: #{ssh_info[:host]}:#{ssh_info[:port]}")
                Net::SSH.start(ssh_info[:host], ssh_info[:username], connect_opts)
              ensure
                # Make sure we output the connection log
                @logger.debug("== Net-SSH connection debug-level log START ==")
                @logger.debug(ssh_logger_io.string)
                @logger.debug("== Net-SSH connection debug-level log END ==")
              end
            end
          end
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
        rescue NotImplementedError
          # This is raised if a private key type that Net-SSH doesn't support
          # is used. Show a nicer error.
          raise Vagrant::Errors::SSHKeyTypeNotSupported
        end

        @connection = connection

        # This is hacky but actually helps with some issues where
        # Net::SSH is simply not robust enough to handle... see
        # issue #391, #455, etc.
        sleep 4

        # Yield the connection that is ready to be used and
        # return the value of the block
        return yield connection if block_given?
      end

      # Executes the command on an SSH connection within a login shell.
      def shell_execute(connection, command, sudo=false)
        @logger.info("Execute: #{command} (sudo=#{sudo.inspect})")
        exit_status = nil

        # Determine the shell to execute. If we are using `sudo` then we
        # need to wrap the shell in a `sudo` call.
        shell = @machine.config.ssh.shell
        shell = "sudo -H #{shell}" if sudo

        # Open the channel so we can execute or command
        channel = connection.open_channel do |ch|
          ch.exec(shell) do |ch2, _|
            # Setup the channel callbacks so we can get data and exit status
            ch2.on_data do |ch3, data|
              # Filter out the clear screen command
              data = remove_ansi_escape_codes(data)
              @logger.debug("stdout: #{data}")
              yield :stdout, data if block_given?
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
            end

            # Set the terminal
            ch2.send_data "export TERM=vt100\n"

            # Output the command
            ch2.send_data "#{command}\n"

            # Remember to exit or this channel will hang open
            ch2.send_data "exit\n"

            # Send eof to let server know we're done
            ch2.eof!
          end
        end

        # Wait for the channel to complete
        channel.wait

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
    end
  end
end
