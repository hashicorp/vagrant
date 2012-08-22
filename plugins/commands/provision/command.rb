require 'optparse'

module VagrantPlugins
  module CommandProvision
    class Command < Vagrant.plugin("1", :command)
      def execute
        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant provision [vm-name]"
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        # Go over each VM and provision!
        @logger.debug("'provision' each target VM...")
        with_target_vms(argv) do |machine|
          machine.action(:provision)
        end

        # Success, exit status 0
        0
      end
    end
  end
end
