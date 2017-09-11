require "timeout"

require "log4r"

require "vagrant/util/retryable"
require "vagrant/util/silence_warnings"

Vagrant::Util::SilenceWarnings.silence! do
  require "winrm"
end

require "winrm-elevated"
require "winrm-fs"

module VagrantPlugins
  module CommunicatorWinRM
    class WinRMShell
      include Vagrant::Util::Retryable

      # These are the exceptions that we retry because they represent
      # errors that are generally fixed from a retry and don't
      # necessarily represent immediate failure cases.
      @@exceptions_to_retry_on = [
        HTTPClient::KeepAliveDisconnected,
        WinRM::WinRMHTTPTransportError,
        WinRM::WinRMAuthorizationError,
        WinRM::WinRMWSManFault,
        Errno::EACCES,
        Errno::EADDRINUSE,
        Errno::ECONNREFUSED,
        Errno::ECONNRESET,
        Errno::ENETUNREACH,
        Errno::EHOSTUNREACH,
        Timeout::Error
      ]

      attr_reader :logger
      attr_reader :host
      attr_reader :port
      attr_reader :username
      attr_reader :password
      attr_reader :execution_time_limit
      attr_reader :config

      def initialize(host, port, config)
        @logger = Log4r::Logger.new("vagrant::communication::winrmshell")
        @logger.debug("initializing WinRMShell")

        @host                  = host
        @port                  = port
        @username              = config.username
        @password              = config.password
        @execution_time_limit  = config.execution_time_limit
        @config                = config
      end

      def powershell(command, opts = {}, &block)
        connection.shell(:powershell) do |shell|
          execute_with_rescue(shell, command, &block)
        end
      end

      def cmd(command, opts = {}, &block)
        shell_opts = {}
        shell_opts[:codepage] = @config.codepage if @config.codepage
        connection.shell(:cmd, shell_opts) do |shell|
          execute_with_rescue(shell, command, &block)
        end
      end

      def elevated(command, opts = {}, &block)
        connection.shell(:elevated) do |shell|
          shell.interactive_logon = opts[:interactive] || false
          execute_with_rescue(shell, command, &block)
        end
      end

      def wql(query, opts = {}, &block)
        retryable(tries: @config.max_tries, on: @@exceptions_to_retry_on, sleep: @config.retry_delay) do
          connection.run_wql(query)
        end
      rescue => e
        raise_winrm_exception(e, "run_wql", query)
      end

      # @param from [Array<String>, String] a single path or folder, or an
      #        array of paths and folders to upload to the guest
      # @param to [String] a path or folder on the guest to upload to
      # @return [FixNum] Total size transfered from host to guest
      def upload(from, to)
        file_manager = WinRM::FS::FileManager.new(connection)
        if from.is_a?(Array)
          # Preserve return FixNum of bytes transfered
          return_bytes = 0
          from.each do |file|
            return_bytes += file_manager.upload(file, to)
          end
          return return_bytes
        else
          file_manager.upload(from, to)
        end
      end

      def download(from, to)
        file_manager = WinRM::FS::FileManager.new(connection)
        file_manager.download(from, to)
      end

      protected

      def execute_with_rescue(shell, command, &block)
        handle_output(shell, command, &block)
      rescue => e
        raise_winrm_exception(e, shell.class.name.split("::").last, command)
      end

      def handle_output(shell, command, &block)
        output = shell.run(command) do |out, err|
          block.call(:stdout, out) if block_given? && out
          block.call(:stderr, err) if block_given? && err
        end

        @logger.debug("Output: #{output.inspect}")

        # Verify that we didn't get a parser error, and if so we should
        # set the exit code to 1. Parse errors return exit code 0 so we
        # need to do this.
        if output.exitcode == 0
          if output.stderr.include?("ParserError")
            @logger.warn("Detected ParserError, setting exit code to 1")
            output.exitcode = 1
          end
        end

        return output
      end

      def raise_winrm_exception(exception, shell = nil, command = nil)
        case exception
        when WinRM::WinRMAuthorizationError
          raise Errors::AuthenticationFailed,
              user: @config.username,
              password: @config.password,
              endpoint: endpoint,
              message: exception.message
        when WinRM::WinRMHTTPTransportError
          raise Errors::ExecutionError,
            shell: shell,
            command: command,
            message: exception.message
        when OpenSSL::SSL::SSLError
          raise Errors::SSLError, message: exception.message
        when HTTPClient::TimeoutError
          raise Errors::ConnectionTimeout, message: exception.message
        when Errno::ETIMEDOUT
          raise Errors::ConnectionTimeout
          # This is raised if the connection timed out
        when Errno::ECONNREFUSED
          # This is raised if we failed to connect the max amount of times
          raise Errors::ConnectionRefused
        when Errno::ECONNRESET
          # This is raised if we failed to connect the max number of times
          # due to an ECONNRESET.
          raise Errors::ConnectionReset
        when Errno::EHOSTDOWN
          # This is raised if we get an ICMP DestinationUnknown error.
          raise Errors::HostDown
        when Errno::EHOSTUNREACH
          # This is raised if we can't work out how to route traffic.
          raise Errors::NoRoute
        else
          raise Errors::ExecutionError,
            shell: shell,
            command: command,
            message: exception.message
        end
      end

      def new_connection
        @logger.info("Attempting to connect to WinRM...")
        @logger.info("  - Host: #{@host}")
        @logger.info("  - Port: #{@port}")
        @logger.info("  - Username: #{@config.username}")
        @logger.info("  - Transport: #{@config.transport}")

        client = ::WinRM::Connection.new(endpoint_options)
        client.logger = @logger
        client
      end

      def connection
        @connection ||= new_connection
      end

      def endpoint
        case @config.transport.to_sym
        when :ssl
          "https://#{@host}:#{@port}/wsman"
        when :plaintext, :negotiate
          "http://#{@host}:#{@port}/wsman"
        else
          raise Errors::WinRMInvalidTransport, transport: @config.transport
        end
      end

      def endpoint_options
        { endpoint: endpoint,
          transport: @config.transport,
          operation_timeout: @config.timeout,
          user: @username,
          password: @password,
          host: @host,
          port: @port,
          basic_auth_only: @config.basic_auth_only,
          no_ssl_peer_verification: !@config.ssl_peer_verification,
          retry_delay: @config.retry_delay,
          retry_limit: @config.max_tries }
      end
    end #WinShell class
  end
end
