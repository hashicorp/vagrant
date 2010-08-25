module Vagrant
  module Command
    class ReloadCommand < NamedBase
      desc "Reload the environment, halting it then restarting it."
      register "reload"

      def execute
        target_vms.each do |vm|
          if vm.created?
            vm.reload
          else
            vm.env.ui.info "VM not created. Moving on..."
          end
        end
      end
    end
  end
end
