require 'optparse'

module VagrantPlugins
  module CommandHalt
    class Command < Vagrant.plugin("2", :command)
      def self.synopsis
        "stops the vagrant machine"
      end

      def execute
        options = {}
        options[:force] = false

        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant halt [options] [name|id]"
          o.separator ""
          o.separator "Options:"
          o.separator ""

          o.on("-f", "--force", "Force shut down (equivalent of pulling power)") do |f|
            options[:force] = f
          end
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        @logger.debug("Halt command: #{argv.inspect} #{options.inspect}")
        with_target_vms(argv, reverse: true) do |vm|
          vm.action(:halt, force_halt: options[:force])
        end

        # Success, exit status 0
        0
      end
    end
  end
end
