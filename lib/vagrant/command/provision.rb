module Vagrant
  module Command
    class ProvisionCommand < Base
      desc "Rerun the provisioning scripts on a running VM"
      register "provision"

      def execute
        target_vms.each do |vm|
          if vm.created? && vm.vm.running?
            vm.provision
          else
            vm.env.ui.info "VM not created. Moving on..."
          end
        end
      end
    end
  end
end
