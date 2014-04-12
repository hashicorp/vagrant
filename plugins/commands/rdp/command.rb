require "optparse"

module VagrantPlugins
  module CommandRDP
    class Command < Vagrant.plugin("2", :command)
      def self.synopsis
        "connects to machine via RDP"
      end

      def execute
        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant rdp [options] [name]"
        end

        # Parse the options and return if we don't have any target.
        argv = parse_options(opts)
        return if !argv

        # Check if the host even supports RDP
        raise Errors::HostUnsupported if !@env.host.capability?(:rdp_client)

        # Execute RDP if we can
        with_target_vms(argv, single_target: true) do |machine|
        end
      end
    end
  end
end
