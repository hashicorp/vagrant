require 'optparse'

module Vagrant
  module Command
    class Destroy < Base
      def execute
        opts = OptionParser.new do |opts|
          opts.banner = "Usage: vagrant destroy [vm-name]"
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        @logger.debug("'Destroy' each target VM...")
        with_target_vms(argv[0]) do |vm|
          if vm.created?
            @logger.info("Destroying: #{vm.name}")
            vm.destroy
          else
            @logger.info("Not destroying #{vm.name}, since it isn't created.")
            vm.ui.info I18n.t("vagrant.commands.common.vm_not_created")
          end
        end
      end
    end
  end
end
