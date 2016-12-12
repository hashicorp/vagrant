require "timeout"

require "log4r"

require "vagrant/util/retryable"
require "vagrant/util/silence_warnings"

Vagrant::Util::SilenceWarnings.silence! do
  require "winrm"
end

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

      def powershell(command, &block)
        # Ensure an exit code
        command += "\r\nif ($?) { exit 0 } else { if($LASTEXITCODE) { exit $LASTEXITCODE } else { exit 1 } }"
        session.create_executor do |executor|
          execute_with_rescue(executor.method("run_powershell_script"), command, &block)
        end
      end

      def cmd(command, &block)
        session.create_executor do |executor|
          execute_with_rescue(executor.method("run_cmd"), command, &block)
        end
      end

      def wql(query, &block)
        retryable(tries: @config.max_tries, on: @@exceptions_to_retry_on, sleep: @config.retry_delay) do
          handle_output(session.method("run_wql"), query, &block)
        end
      rescue => e
        raise_winrm_exception(e, "run_wql", query)
      end

      def upload(from, to)
        file_manager = WinRM::FS::FileManager.new(session)
        file_manager.upload(from, to)
      end

      def download(from, to)
        file_manager = WinRM::FS::FileManager.new(session)
        file_manager.download(from, to)
      end

      protected

      def execute_with_rescue(method, command, &block)
        handle_output(method, command, &block)
      rescue => e
        raise_winrm_exception(e, method.name, command)
      end

      def handle_output(execute_method, command, &block)
        output = execute_method.call(command) do |out, err|
          block.call(:stdout, out) if block_given? && out
          block.call(:stderr, err) if block_given? && err
        end

        @logger.debug("Output: #{output.inspect}")

        # Verify that we didn't get a parser error, and if so we should
        # set the exit code to 1. Parse errors return exit code 0 so we
        # need to do this.
        if output[:exitcode] == 0
          (output[:data] || []).each do |data|
            next if !data[:stderr]
            if data[:stderr].include?("ParserError")
              @logger.warn("Detected ParserError, setting exit code to 1")
              output[:exitcode] = 1
              break
            end
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

      def new_session
        @logger.info("Attempting to connect to WinRM...")
        @logger.info("  - Host: #{@host}")
        @logger.info("  - Port: #{@port}")
        @logger.info("  - Username: #{@config.username}")
        @logger.info("  - Transport: #{@config.transport}")

        client = ::WinRM::WinRMWebService.new(endpoint, @config.transport.to_sym, endpoint_options)
        client.set_timeout(@config.timeout)
        client.logger = @logger
        client
      end

      def session
        @session ||= new_session
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
        { user: @username,
          pass: @password,
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
