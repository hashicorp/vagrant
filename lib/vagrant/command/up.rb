module Vagrant
  module Command
    class UpCommand < NamedBase
      class_option :provision, :type => :boolean, :default => true, :desc => "Enable or disable provisioning"
      class_option :provisioners, :type => :array, :desc => "Load only the specified provisioners"
      register "up", "Creates the Vagrant environment"

      def execute
        target_vms.each do |vm|
          if vm.created?
            vm.env.ui.info I18n.t("vagrant.commands.up.vm_created")
            vm.start("provision.enabled" => options[:provision],
                     "provision.provisioners" => options[:provisioners])
          else
            vm.up("provision.enabled" => options[:provision],
                  "provision.provisioners" => options[:provisioners])
          end
        end
      end
    end
  end
end
