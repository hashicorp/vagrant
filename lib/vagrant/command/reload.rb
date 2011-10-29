module Vagrant
  module Command
    class ReloadCommand < NamedBase
      register "reload", "Reload the environment, halting it then restarting it."

      def execute
        target_vms.each do |vm|
          if vm.created?
            vm.reload
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
