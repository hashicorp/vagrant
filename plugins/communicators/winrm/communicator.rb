require "timeout"

require "log4r"

require_relative "helper"
require_relative "shell"
require_relative "command_filter"

module VagrantPlugins
  module CommunicatorWinRM
    # Provides communication channel for Vagrant commands via WinRM.
    class Communicator < Vagrant.plugin("2", :communicator)
      def self.match?(machine)
        # This is useless, and will likely be removed in the future (this
        # whole method).
        true
      end

      def initialize(machine)
        @cmd_filter = CommandFilter.new()
        @logger     = Log4r::Logger.new("vagrant::communication::winrm")
        @machine    = machine
        @shell      = nil

        @logger.info("Initializing WinRMCommunicator")
      end

      def wait_for_ready(timeout)
        Timeout.timeout(timeout) do
          # Wait for winrm_info to be ready
          winrm_info = nil
          while true
            winrm_info = Helper.winrm_info(@machine)
            break if winrm_info
            sleep 0.5
          end

          # Got it! Let the user know what we're connecting to.
          @machine.ui.detail("WinRM address: #{shell.host}:#{shell.port}")
          @machine.ui.detail("WinRM username: #{shell.username}")
          @machine.ui.detail("WinRM transport: #{shell.config.transport}")

          last_message = nil
          last_message_repeat_at = 0
          while true
            message  = nil
            begin
              begin
                return true if ready?
              rescue Vagrant::Errors::VagrantError => e
                @logger.info("WinRM not ready: #{e.inspect}")
                raise
              end
            rescue Errors::ConnectionTimeout
              message = "Connection timeout."
            rescue Errors::AuthenticationFailed
              message = "Authentication failure."
            rescue Errors::Disconnected
              message = "Remote connection disconnect."
            rescue Errors::ConnectionRefused
              message = "Connection refused."
            rescue Errors::ConnectionReset
              message = "Connection reset."
            rescue Errors::HostDown
              message = "Host appears down."
            rescue Errors::NoRoute
              message = "Host unreachable."
            rescue Errors::TransientError => e
              # Any other retriable errors
              message = e.message
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
        @logger.info("Checking whether WinRM is ready...")

        result = Timeout.timeout(@machine.config.winrm.timeout) do
          shell(true).powershell("hostname")
        end

        @logger.info("WinRM is ready!")
        return true
      rescue Errors::TransientError => e
        # We catch a `TransientError` which would signal that something went
        # that might work if we wait and retry.
        @logger.info("WinRM not up: #{e.inspect}")

        # We reset the shell to trigger calling of winrm_finder again.
        # This resolves a problem when using vSphere where the winrm_info was not refreshing
        # thus never getting the correct hostname.
        @shell = nil
        return false
      end

      def shell(reload=false)
        @shell = nil if reload
        @shell ||= create_shell
      end

      def execute(command, opts={}, &block)
        # If this is a *nix command with no Windows equivilant, don't run it
        command = @cmd_filter.filter(command)
        return 0 if command.empty?

        opts = {
          command:     command,
          elevated:    false,
          error_check: true,
          error_class: Errors::WinRMBadExitStatus,
          error_key:   nil, # use the error_class message key
          good_exit:   0,
          shell:       :powershell,
        }.merge(opts || {})

        opts[:good_exit] = Array(opts[:good_exit])
        command = wrap_in_scheduled_task(command) if opts[:elevated]
        output = shell.send(opts[:shell], command, &block)
        execution_output(output, opts)
      end
      alias_method :sudo, :execute

      def test(command, opts=nil)
        # If this is a *nix command (which we know about) with no Windows
        # equivilant, assume failure
        command = @cmd_filter.filter(command)
        return false if command.empty?

        opts = {
          command:     command,
          elevated:    false,
          error_check: false,
        }.merge(opts || {})

        # If we're passed a *nix command which PS can't parse we get exit code
        # 0, but output in stderr. We need to check both exit code and stderr.
        output = shell.send(:powershell, command)
        return output[:exitcode] == 0 && flatten_stderr(output).length == 0
      end

      def upload(from, to)
        @logger.info("Uploading: #{from} to #{to}")
        shell.upload(from, to)
      end

      def download(from, to)
        @logger.info("Downloading: #{from} to #{to}")
        shell.download(from, to)
      end

      protected

      # This creates anew WinRMShell based on the information we know
      # about this machine.
      def create_shell
        winrm_info = Helper.winrm_info(@machine)

        WinRMShell.new(
          winrm_info[:host],
          winrm_info[:port],
          @machine.config.winrm
        )
      end

      # Creates and uploads a PowerShell script which wraps a command in a
      # scheduled task. The scheduled task allows commands to run on the guest
      # as a true local admin without any of the restrictions that WinRM puts
      # in place.
      #
      # @return The wrapper command to execute
      def wrap_in_scheduled_task(command)
        path = File.expand_path("../scripts/elevated_shell.ps1", __FILE__)
        script = Vagrant::Util::TemplateRenderer.render(path)
        guest_script_path = "c:/tmp/vagrant-elevated-shell.ps1"
        file = Tempfile.new(["vagrant-elevated-shell", "ps1"])
        begin
          file.write(script)
          file.fsync
          file.close
          upload(file.path, guest_script_path)
        ensure
          file.close
          file.unlink
        end

        # convert to double byte unicode string then base64 encode
        # just like PowerShell -EncodedCommand expects
        wrapped_encoded_command = Base64.strict_encode64(
          "#{command}; exit $LASTEXITCODE".encode('UTF-16LE', 'UTF-8'))

        "powershell -executionpolicy bypass -file \"#{guest_script_path}\" " +
          "-username \"#{shell.username}\" -password \"#{shell.password}\" " +
          "-encoded_command \"#{wrapped_encoded_command}\""
      end

      # Handles the raw WinRM shell result and converts it to a
      # standard Vagrant communicator result
      def execution_output(output, opts)
        if opts[:shell] == :wql
          return output
        elsif opts[:error_check] && \
          !opts[:good_exit].include?(output[:exitcode])
          raise_execution_error(output, opts)
        end
        output[:exitcode]
      end

      def raise_execution_error(output, opts)
        # WinRM can return multiple stderr and stdout entries
        error_opts = opts.merge(
          stdout: flatten_stdout(output),
          stderr: flatten_stderr(output)
        )

        # Use a different error message key if the caller gave us one,
        # otherwise use the error's default message
        error_opts[:_key] = opts[:error_key] if opts[:error_key]

        # Raise the error, use the type the caller gave us or the comm default
        raise opts[:error_class], error_opts
      end


      # TODO: Replace with WinRM Output class when WinRM 1.3 is released
      def flatten_stderr(output)
        output[:data].map do | line |
          line[:stderr]
        end.compact.join
      end

      def flatten_stdout(output)
        output[:data].map do | line |
          line[:flatten_stdout]
        end.compact.join
      end
    end #WinRM class
  end
end
