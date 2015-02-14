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
          command:     command,
          elevated:    false,
          error_check: true,
          error_class: Errors::WinRMBadExitStatus,
          error_key:   nil, # use the error_class message key
          good_exit:   0,
          shell:       :powershell,
        }.merge(opts || {})

        opts[:good_exit] = Array(opts[:good_exit])

        if opts[:elevated]
          guest_script_path = create_elevated_shell_script(command)
          command = "powershell -executionpolicy bypass -file #{guest_script_path}"
        end

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

      # Creates and uploads a PowerShell script which wraps the specified
      # command in a scheduled task. The scheduled task allows commands to
      # run on the guest as a true local admin without any of the restrictions
      # that WinRM puts in place.
      #
      # @return The path to elevated_shell.ps1 on the guest
      def create_elevated_shell_script(command)
        path = File.expand_path("../scripts/elevated_shell.ps1", __FILE__)
        script = Vagrant::Util::TemplateRenderer.render(path, options: {
          username: shell.username,
          password: shell.password,
          command: command.gsub("\"", "`\""),
        })
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
        guest_script_path
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
