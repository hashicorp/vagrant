module Vagrant
  module Command
    class DestroyCommand < Base
      desc "Destroy the environment, deleting the created virtual machines."
      register "destroy"

      def execute
        target_vms.each do |vm|
          if vm.created?
            vm.destroy
          else
            vm.env.ui.info "VM not created. Moving on..."
          end
        end
      end
    end
  end
end
