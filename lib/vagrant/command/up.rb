module Vagrant
  module Command
    class UpCommand < NamedBase
      class_option :provision, :type => :boolean, :default => true
      register "up", "Creates the Vagrant environment"

      def execute
        with_target_vms do |vm|
          if vm.created?
            vm.env.ui.info I18n.t("vagrant.commands.up.vm_created")
            vm.start("provision.enabled" => options[:provision])
          else
            vm.up("provision.enabled" => options[:provision])
          end
        end
      end
    end
  end
end
