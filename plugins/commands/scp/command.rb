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
          o.separator ""
          o.separator "Options:"
          o.separator ""

          #o.on("-c", "--command COMMAND", "Execute an SSH command directly") do |c|
          #  options[:command] = c
          #end

          #o.on("-p", "--plain", "Plain mode, leaves authentication up to user") do |p|
          #  options[:plain_mode] = p
          #end
        end

        # Parse options and return if a source and a destination are not provided.
        argv = parse_options(opts)
        return if !argv || argv.length != 2

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

