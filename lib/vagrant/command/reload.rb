require 'optparse'

module Vagrant
  module Command
    class Reload < Base
      def execute
        options = {}

        opts = OptionParser.new do |opts|
          opts.banner = "Usage: vagrant reload [vm-name]"
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        @logger.debug("'reload' each target VM...")
        with_target_vms(argv[0]) do |vm|
          if vm.created?
            @logger.info("Reloading: #{vm.name}")
            vm.reload
          else
            @logger.info("Not created: #{vm.name}. Not reloading.")
            vm.ui.info I18n.t("vagrant.commands.common.vm_not_created")
          end
        end
      end
    end
  end
end
