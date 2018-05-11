require 'optparse'

module VagrantPlugins
  module CommandSuspend
    class Command < Vagrant.plugin("2", :command)
      def self.synopsis
        "suspends the machine"
      end

      def execute
        options = {}
        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant suspend [options] [name|id]"
          o.separator ""
          o.on("-a", "--all-global", "Suspend all running vms globally.") do |p|
            options[:all] = true
          end
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        @logger.debug("'suspend' each target VM...")
        target = []
        if options[:all]
          if argv.size > 0
            raise Vagrant::Errors::CommandSuspendAllArgs
          end

          m = @env.machine_index.each { |m| m }
          target = m.keys
        else
          target = argv
        end

        with_target_vms(target) do |vm|
          vm.action(:suspend)
        end

        # Success, exit status 0
        0
      end
    end
  end
end
