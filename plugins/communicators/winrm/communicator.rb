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

      def ready?
        @logger.info("Checking whether WinRM is ready...")

        Timeout.timeout(@machine.config.winrm.timeout) do
          shell(true).powershell("hostname")
        end

        @logger.info("WinRM is ready!")
        return true
      rescue Vagrant::Errors::VagrantError => e
        # We catch a `VagrantError` which would signal that something went
        # wrong expectedly in the `connect`, which means we didn't connect.
        @logger.info("WinRM not up: #{e.inspect}")

        # We reset the shell to trigger calling of winrm_finder again.
        # This resolves a problem when using vSphere where the ssh_info was not refreshing
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
          error_check: true,
          error_class: Errors::ExecutionError,
          error_key:   :execution_error,
          command:     command,
          shell:       :powershell,
          elevated:    false
        }.merge(opts || {})

        if opts[:elevated]
          path = File.expand_path("../scripts/elevated_shell.ps1", __FILE__)
          command = Vagrant::Util::TemplateRenderer.render(path, options: {
            username: shell.username,
            password: shell.password,
            command: command,
          })
        end

        output = shell.send(opts[:shell], command, &block)
        execution_output(output, opts)
      end
      alias_method :sudo, :execute

      def test(command, opts=nil)
        # If this is a *nix command with no Windows equivilant, assume failure
        command = @cmd_filter.filter(command)
        return false if command.empty?

        opts = { :error_check => false }.merge(opts || {})
        execute(command, opts) == 0
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
        host_address = Helper.winrm_address(@machine)
        host_port    = Helper.winrm_port(@machine)

        WinRMShell.new(
          host_address,
          @machine.config.winrm.username,
          @machine.config.winrm.password,
          port: host_port,
          timeout_in_seconds: @machine.config.winrm.timeout,
          max_tries: @machine.config.winrm.max_tries,
        )
      end

      # Handles the raw WinRM shell result and converts it to a
      # standard Vagrant communicator result
      def execution_output(output, opts)
        if opts[:shell] == :wql
          return output
        elsif opts[:error_check] && output[:exitcode] != 0
          raise_execution_error(output, opts)
        end
        output[:exitcode]
      end

      def raise_execution_error(output, opts)
        # The error classes expect the translation key to be _key, but that makes for an ugly
        # configuration parameter, so we set it here from `error_key`
        msg = "Command execution failed with an exit code of #{output[:exitcode]}"
        error_opts = opts.merge(_key: opts[:error_key], message: msg)
        raise opts[:error_class], error_opts
      end
    end #WinRM class
  end
end
