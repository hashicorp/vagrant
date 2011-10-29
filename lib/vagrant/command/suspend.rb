module Vagrant
  module Command
    class SuspendCommand < NamedBase
      register "suspend", "Suspend a running Vagrant environment."

      def execute
        target_vms.each do |vm|
          if vm.created?
            vm.suspend
          else
            vm.env.ui.info I18n.t("vagrant.commands.common.vm_not_created")
          end
          vm.ssh.exit_all
          vm.ssh.show_all_connection_output
        end
      end
    end
  end
end
