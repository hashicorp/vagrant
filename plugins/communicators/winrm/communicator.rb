require "timeout"

require "log4r"

require_relative "shell"

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
        @machine = machine
        @logger  = Log4r::Logger.new("vagrant::communication::winrm")
        @shell   = nil

        @logger.info("Initializing WinRMCommunicator")
      end

      def ready?
        @logger.info("Checking whether WinRM is ready...")

        Timeout.timeout(@machine.config.winrm.timeout) do
          shell.powershell("hostname")
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

      def shell
        @shell ||= create_shell
      end

      def execute(command, opts={}, &block)
        opts = {
          :error_check => true,
          :error_class => Errors::ExecutionError,
          :error_key   => :execution_error,
          :command     => command,
          :shell       => :powershell
        }.merge(opts || {})
        exit_status = do_execute(command, opts[:shell], &block)
        if opts[:error_check] && exit_status != 0
          raise_execution_error(opts, exit_status)
        end
        exit_status
      end
      alias_method :sudo, :execute

      def test(command, opts=nil)
        @logger.debug("Testing: #{command}")

        # HACK: to speed up Vagrant 1.2 OS detection, skip checking for *nix OS
        return false unless (command =~ /^uname|^cat \/etc|^cat \/proc|grep 'Fedora/).nil?

        opts = { :error_check => false }.merge(opts || {})
        execute(command, opts) == 0
      end

      def upload(from, to)
        @logger.debug("Uploading: #{from} to #{to}")
        shell.upload(from, to)
      end

      def download(from, to)
        @logger.debug("Downloading: #{from} to #{to}")
        shell.download(from, to)
      end

      protected

      # This creates anew WinRMShell based on the information we know
      # about this machine.
      def create_shell
        host_address = @machine.config.winrm.host
        if !host_address
          ssh_info = @machine.ssh_info
          raise Errors::WinRMNotReady if !ssh_info
          host_address = ssh_info[:host]
        end

        host_port = @machine.config.winrm.port
        if @machine.config.winrm.guest_port
          @logger.debug("Searching for WinRM host port to match: " +
            @machine.config.winrm.guest_port.to_s)

          # Search by guest port if we can. We use a provider capability
          # if we have it. Otherwise, we just scan the Vagrantfile defined
          # ports.
          port = nil
          if @machine.provider.capability?(:forwarded_ports)
            @machine.provider.capability(:forwarded_ports).each do |host, guest|
              if guest == @machine.config.winrm.guest_port
                port = host
                break
              end
            end
          end

          if !port
            machine.config.vm.networks.each do |type, netopts|
              next if type != :forwarded_port
              next if !netopts[:host]
              if netopts[:guest] == @machine.config.winrm.guest_port
                port = netopts[:host]
                break
              end
            end
          end

          # Set it if we found it
          if port
            @logger.debug("Found forwarded port: #{host_port}")
            host_port = port
          end
        end

        WinRMShell.new(
          host_address,
          @machine.config.winrm.username,
          @machine.config.winrm.password,
          port: host_port,
          timeout_in_seconds: @machine.config.winrm.timeout,
          max_tries: @machine.config.winrm.max_tries,
        )
      end

      def do_execute(command, shell, &block)
        if shell.eql? :cmd
          shell.cmd(command, &block)[:exitcode]
        else
          script  = File.expand_path("../scripts/command_alias.ps1", __FILE__)
          script  = File.read(script)
          command = script << "\r\n" << command << "\r\nexit $LASTEXITCODE"
          shell.powershell(command, &block)[:exitcode]
        end
      end

      def raise_execution_error(opts, exit_code)
        # The error classes expect the translation key to be _key, but that makes for an ugly
        # configuration parameter, so we set it here from `error_key`
        msg = "Command execution failed with an exit code of #{exit_code}"
        error_opts = opts.merge(:_key => opts[:error_key], :message => msg)
        raise opts[:error_class], error_opts
      end
    end #WinRM class
  end
end
