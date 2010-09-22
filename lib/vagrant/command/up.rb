module Vagrant
  module Command
    class UpCommand < NamedBase
      class_option :provision, :type => :boolean, :default => true
      register "up", "Creates the Vagrant environment"

      def execute
        # TODO: Make the options[:provision] actually mean something
        target_vms.each do |vm|
          if vm.created?
            vm.env.ui.info I18n.t("vagrant.commands.up.vm_created")
            vm.start
          else
            vm.up
          end
        end
      end
    end
  end
end
