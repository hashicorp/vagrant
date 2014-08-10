require "optparse"

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
          o.banner = "Usage: vagrant ps [-- extra ps args]"
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

        # Check if the host even supports ps remoting
        #raise Errors::HostUnsupported if !@env.host.capability?(:ps_remoting)

        # Execute RDP if we can
        with_target_vms(argv, single_target: true) do |machine|
          if !machine.communicate.ready?
            raise Vagrant::Errors::VMNotCreatedError
          end

          if machine.config.vm.communicator != :winrm || !machine.provider.capability?(:winrm_info)
            raise Errors::WinRMNotReady
          end

          ps_info = Helper.winrm_info(@machine)
          # raise Errors::RDPUndetected if !rdp_info

          # Extra arguments if we have any
          ps_info[:extra_args] = options[:extra_args]

          machine.ui.detail(
            "Creating powershell session to #{ps_info[:host]}:#{ps_info[:port]}")
          machine.ui.detail("Username: #{ps_info[:username]}")

          @env.host.capability(:ps_client, ps_info)
        end
      end

    end
  end
end
