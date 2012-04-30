require 'optparse'

module VagrantPlugins
  module CommandProvision
    class Command < Vagrant::Command::Base
      def execute
        options = {}

        opts = OptionParser.new do |opts|
          opts.banner = "Usage: vagrant provision [vm-name]"
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        # Go over each VM and provision!
        @logger.debug("'provision' each target VM...")
        with_target_vms(argv) do |vm|

          if vm.created?
            if vm.state == :running
              @logger.info("Provisioning: #{vm.name}")
              vm.provision
            else
              @logger.info("#{vm.name} not running. Not provisioning.")
              vm.ui.info I18n.t("vagrant.commands.common.vm_not_running")
            end
          else
            @logger.info("#{vm.name} not created. Not provisioning.")
            vm.ui.info I18n.t("vagrant.commands.common.vm_not_created")
          end
        end

        # Success, exit status 0
        0
       end
    end
  end
end
