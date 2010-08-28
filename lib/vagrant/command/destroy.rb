module Vagrant
  module Command
    class DestroyCommand < NamedBase
      desc "Destroy the environment, deleting the created virtual machines"
      register "destroy"

      def execute
        target_vms.each do |vm|
          if vm.created?
            vm.destroy
          else
            vm.env.ui.info "vagrant.commands.common.vm_not_created"
          end
        end
      end
    end
  end
end
