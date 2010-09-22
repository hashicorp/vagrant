module Vagrant
  module Command
    class DestroyCommand < NamedBase
      register "destroy", "Destroy the environment, deleting the created virtual machines"

      def execute
        target_vms.each do |vm|
          if vm.created?
            vm.destroy
          else
            vm.env.ui.info I18n.t("vagrant.commands.common.vm_not_created")
          end
        end
      end
    end
  end
end
