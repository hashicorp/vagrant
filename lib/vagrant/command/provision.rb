module Vagrant
  module Command
    class ProvisionCommand < NamedBase
      desc "Rerun the provisioning scripts on a running VM"
      register "provision"

      def execute
        target_vms.each do |vm|
          if vm.created? && vm.vm.running?
            vm.provision
          else
            vm.env.ui.info "vagrant.commands.common.vm_not_created"
          end
        end
      end
    end
  end
end
