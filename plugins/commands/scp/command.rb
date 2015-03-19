require 'optparse'

module VagrantPlugins
  module CommandSCP
    class Command < Vagrant.plugin("2", :command)
      def self.synopsis
        "copies files from/to machine via SCP"
      end

      def execute
        options = {}

        opts = OptionParser.new do |o|
          o.banner = <<-BANNER
          Usage: vagrant scp vagrant:[PATH] [DEST-PATH] (vm to host)
                 vagrant scp [PATH] vagrant:[DEST-PATH] (host to vm)
          BANNER
        end

        # Parse destination and source
        argv = parse_options(opts)
        dirs = parse_dirs(argv)

        with_target_vms([], single_target: true) do |vm|
          vm.action(:scp_exec, dirs)
        end

        # Success, exit status 0
        0
      end

      def parse_dirs(argv)
        { source: argv.first, destination: argv.at(1) }
      end
    end
  end
end

