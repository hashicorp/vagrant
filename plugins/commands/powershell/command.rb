require "optparse"

require "vagrant/util/powershell"
require_relative "../../communicators/winrm/helper"

module VagrantPlugins
  module CommandPS
    class Command < Vagrant.plugin("2", :command)
      def self.synopsis
        "connects to machine via powershell remoting"
      end

      def execute
        options = {}

        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant powershell [-- extra powershell args]"

          o.separator ""
          o.separator "Opens a PowerShell session on the host to the guest"
          o.separator "machine if both support powershell remoting."
          o.separator ""
          o.separator "Options:"
          o.separator ""

          o.on("-c", "--command COMMAND", "Execute a powershell command directly") do |c|
            options[:command] = c
          end

          o.on("-e", "--elevated", "Execute a powershell command with elevated permissions") do |c|
            options[:elevated] = true
          end
        end

        # Parse out the extra args to send to the ps session, which
        # is everything after the "--"
        split_index = @argv.index("--")
        if split_index
          options[:extra_args] = @argv.drop(split_index + 1)
          @argv                = @argv.take(split_index)
        end

        # Parse the options and return if we don't have any target.
        argv = parse_options(opts)
        return if !argv

        # Elevated option enabled means we can only execute commands
        raise Errors::ElevatedNoCommand if !options[:command] && options[:elevated]

        # Execute ps session if we can
        with_target_vms(argv, single_target: true) do |machine|
          if !machine.communicate.ready?
            raise Vagrant::Errors::VMNotCreatedError
          end

          if options[:command]
            if machine.config.vm.communicator != :winrm
              raise VagrantPlugins::CommunicatorWinRM::Errors::WinRMNotReady
            end

            out_code = machine.communicate.execute(options[:command].dup, elevated: options[:elevated]) do |type,data|
              machine.ui.detail(data) if type == :stdout
            end
            if out_code == 0
              machine.ui.success("Command: #{options[:command]} executed successfully with output code #{out_code}.")
            end
            next
          end

          # Check if the host even supports ps remoting
          raise Errors::HostUnsupported if !@env.host.capability?(:ps_client)

          ps_info = VagrantPlugins::CommunicatorWinRM::Helper.winrm_info(machine)
          ps_info[:username] = machine.config.winrm.username
          ps_info[:password] = machine.config.winrm.password
          # Extra arguments if we have any
          ps_info[:extra_args] = options[:extra_args]

          result = ready_ps_remoting_for(machine, ps_info)

          machine.ui.detail(
            "Creating powershell session to #{ps_info[:host]}:#{ps_info[:port]}")
          machine.ui.detail("Username: #{ps_info[:username]}")

          begin
            @env.host.capability(:ps_client, ps_info)
          ensure
            if result["PreviousTrustedHosts"]
              reset_ps_remoting_for(machine, ps_info)
            end
          end
        end
      end

      def ready_ps_remoting_for(machine, ps_info)
        machine.ui.output(I18n.t("vagrant_ps.detecting"))
        script_path = File.expand_path("../scripts/enable_psremoting.ps1", __FILE__)
        args = []
        args << "-hostname" << ps_info[:host]
        args << "-port" << ps_info[:port].to_s
        args << "-username" << ps_info[:username]
        args << "-password" << ps_info[:password]
        result = Vagrant::Util::PowerShell.execute(script_path, *args)
        if result.exit_code != 0
          raise Errors::PowerShellError,
            script: script_path,
            stderr: result.stderr
        end

        result_output = JSON.parse(result.stdout)
        raise Errors::PSRemotingUndetected if !result_output["Success"]
        result_output
      end

      def reset_ps_remoting_for(machine, ps_info)
        machine.ui.output(I18n.t("vagrant_ps.resetting"))
        script_path = File.expand_path("../scripts/reset_trustedhosts.ps1", __FILE__)
        args = []
        args << "-hostname" << ps_info[:host]
        result = Vagrant::Util::PowerShell.execute(script_path, *args)
        if result.exit_code != 0
          raise Errors::PowerShellError,
            script: script_path,
            stderr: result.stderr
        end
      end
    end
  end
end
