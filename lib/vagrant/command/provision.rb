module Vagrant
  module Command
    class ProvisionCommand < NamedBase
      register "provision", "Rerun the provisioning scripts on a running VM"
      class_option :provisioners, :type => :array, :desc => "Load only the specified provisioners"

      def execute
        target_vms.each do |vm|
          if vm.created? && vm.vm.running?
            vm.provision("provision.provisioners" => options[:provisioners])
          else
            vm.env.ui.info I18n.t("vagrant.commands.common.vm_not_created")
          end
        end
      end
    end
  end
end
