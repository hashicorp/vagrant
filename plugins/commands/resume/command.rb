require 'optparse'

module VagrantPlugins
  module CommandResume
    class Command < Vagrant.plugin("2", :command)
      def self.synopsis
        "resume a suspended vagrant machine"
      end

      def execute
        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant resume [vm-name]"
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        @logger.debug("'resume' each target VM...")
        with_target_vms(argv) do |machine|
          machine.action(:resume)
        end

        # Success, exit status 0
        0
      end
    end
  end
end
