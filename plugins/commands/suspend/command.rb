require 'optparse'

module VagrantPlugins
  module CommandSuspend
    class Command < Vagrant.plugin("2", :command)
      def self.synopsis
        "suspends the machine"
      end

      def execute
        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant suspend [name|id]"
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        @logger.debug("'suspend' each target VM...")
        with_target_vms(argv) do |vm|
          vm.action(:suspend)
        end

        # Success, exit status 0
        0
      end
    end
  end
end
