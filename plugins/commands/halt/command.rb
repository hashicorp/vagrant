require 'optparse'

module VagrantPlugins
  module CommandHalt
    class Command < Vagrant.plugin("1", :command)
      def execute
        options = {}

        opts = OptionParser.new do |opts|
          opts.banner = "Usage: vagrant halt [vm-name] [--force] [-h]"

          opts.separator ""

          opts.on("-f", "--force", "Force shut down (equivalent of pulling power)") do |f|
            options[:force] = f
          end
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        @logger.debug("Halt command: #{argv.inspect} #{options.inspect}")
        with_target_vms(argv) do |vm|
          # XXX: "force"
          vm.action(:halt)
        end

        # Success, exit status 0
        0
       end
    end
  end
end
