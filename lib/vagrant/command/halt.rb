require 'optparse'

module Vagrant
  module Command
    class Halt < Base
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
          if vm.created?
            @logger.info("Halting #{vm.name}")
            vm.halt(:force => options[:force])
          else
            @logger.info("Not halting #{vm.name}, since not created.")
            vm.ui.info I18n.t("vagrant.commands.common.vm_not_created")
          end
        end

        # Success, exit status 0
        0
       end
    end
  end
end
