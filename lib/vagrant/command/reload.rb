module Vagrant
  module Command
    class ReloadCommand < NamedBase
      register "reload", "Reload the environment, halting it then restarting it."
      class_option :provisioners, :type => :array, :desc => "Load only the specified provisioners"

      def execute
        target_vms.each do |vm|
          if vm.created?
            vm.reload("provision.provisioners" => options[:provisioners])
          else
            vm.env.ui.info I18n.t("vagrant.commands.common.vm_not_created")
          end
        end
      end
    end
  end
end
