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

          o.on("-a", "--all-global", "Shut down all running vms globally.") do |a|
            options[:all] = true
          end

        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        @logger.debug("Halt command: #{argv.inspect} #{options.inspect}")
        target = []
        if options[:all]
          if argv.size > 0
            raise Vagrant::Errors::CommandHaltAllArgs
          end

          m = @env.machine_index.each { |m| m }
          target = m.keys
        else
          target = argv
        end

        with_target_vms(target, reverse: true) do |vm|
          vm.action(:halt, force_halt: options[:force])
        end

        # Success, exit status 0
        0
      end
    end
  end
end
