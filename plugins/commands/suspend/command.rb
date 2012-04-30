require 'optparse'

module VagrantPlugins
  module CommandSuspend
    class Command < Vagrant::Command::Base
      def execute
        options = {}

        opts = OptionParser.new do |opts|
          opts.banner = "Usage: vagrant suspend [vm-name]"
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        @logger.debug("'suspend' each target VM...")
        with_target_vms(argv) do |vm|
          if vm.created?
            @logger.info("Suspending: #{vm.name}")
            vm.suspend
          else
            @logger.info("Not created: #{vm.name}. Not suspending.")
            vm.ui.info I18n.t("vagrant.commands.common.vm_not_created")
          end
        end

        # Success, exit status 0
        0
       end
    end
  end
end
