module Vagrant
  module Command
    class HaltCommand < NamedBase
      class_option :force, :type => :boolean, :default => false, :aliases => "-f"
      register "halt", "Halt the running VMs in the environment"

      def execute
        target_vms.each do |vm|
          if vm.created?
            vm.halt(options)
          else
            vm.env.ui.info I18n.t("vagrant.commands.common.vm_not_created")
          end
        end
      end
    end
  end
end
