module Vagrant
  module Command
    class UpCommand < NamedBase
      class_option :provision, :type => :boolean, :default => true
      register "up", "Creates the Vagrant environment"

      def execute
        target_vms.each do |vm|
          if vm.created?
            vm.env.ui.info I18n.t("vagrant.commands.up.vm_created")
            vm.start("provision.enabled" => options[:provision])
          else
            vm.up("provision.enabled" => options[:provision])
          end
          vm.ssh.exit_all
          vm.ssh.show_all_connection_output
        end
      end
    end
  end
end
