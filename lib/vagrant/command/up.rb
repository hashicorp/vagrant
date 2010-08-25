module Vagrant
  module Command
    class UpCommand < NamedBase
      desc "Creates the Vagrant environment"
      class_option :provision, :type => :boolean, :default => true
      register "up"

      def execute
        # TODO: Make the options[:provision] actually mean something
        target_vms.each do |vm|
          if vm.created?
            vm.env.ui.info "VM already created. Booting if its not already running..."
            vm.start
          else
            vm.up
          end
        end
      end
    end
  end
end
