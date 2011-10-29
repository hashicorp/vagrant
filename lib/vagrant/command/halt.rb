module Vagrant
  module Command
    class HaltCommand < NamedBase
      class_option :force, :type => :boolean, :default => false, :aliases => "-f"
      register "halt", "Halt the running VMs in the environment"

      def execute
        target_vms.each do |vm|
          if vm.created?
            vm.ssh.exit_all
            vm.halt(options)
            vm.ssh.show_all_connection_output
          else
            vm.env.ui.info I18n.t("vagrant.commands.common.vm_not_created")
          end
        end
      end
    end
  end
end
