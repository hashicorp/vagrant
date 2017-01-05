require "log4r"
require "tempfile"
require "timeout"

require_relative "helper"
require_relative "shell"
require_relative "command_filter"

module VagrantPlugins
  module CommunicatorWinRM
    # Provides communication channel for Vagrant commands via WinRM.
    class Communicator < Vagrant.plugin("2", :communicator)
      include Vagrant::Util

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
            winrm_info = nil
            begin
              winrm_info = Helper.winrm_info(@machine)
            rescue Errors::WinRMNotReady
              @logger.debug("WinRM not ready yet; retrying until boot_timeout is reached.")
            end
            break if winrm_info
            sleep 0.5
          end

          # Got it! Let the user know what we're connecting to.
          @machine.ui.detail("WinRM address: #{shell.host}:#{shell.port}")
          @machine.ui.detail("WinRM username: #{shell.username}")
          @machine.ui.detail("WinRM execution_time_limit: #{shell.execution_time_limit}")
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
          shell(true).cmd("hostname")
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
          interactive: false,
        }.merge(opts || {})

        opts[:shell] = :elevated if opts[:elevated]
        opts[:good_exit] = Array(opts[:good_exit])
        @logger.debug("#{opts[:shell]} executing:\n#{command}")
        output = shell.send(opts[:shell], command, opts, &block)
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
        return output.exitcode == 0 && output.stderr.length == 0
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

      # This creates a new WinRMShell based on the information we know
      # about this machine.
      def create_shell
        winrm_info = Helper.winrm_info(@machine)

        WinRMShell.new(
          winrm_info[:host],
          winrm_info[:port],
          @machine.config.winrm
        )
      end

      # Handles the raw WinRM shell result and converts it to a
      # standard Vagrant communicator result
      def execution_output(output, opts)
        if opts[:shell] == :wql
          return output
        elsif opts[:error_check] && \
          !opts[:good_exit].include?(output.exitcode)
          raise_execution_error(output, opts)
        end
        output.exitcode
      end

      def raise_execution_error(output, opts)
        # WinRM can return multiple stderr and stdout entries
        error_opts = opts.merge(
          stdout: output.stdout,
          stderr: output.stderr
        )

        # Use a different error message key if the caller gave us one,
        # otherwise use the error's default message
        error_opts[:_key] = opts[:error_key] if opts[:error_key]

        # Raise the error, use the type the caller gave us or the comm default
        raise opts[:error_class], error_opts
      end
    end #WinRM class
  end
end
