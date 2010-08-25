module Vagrant
  module Command
    class SuspendCommand < NamedBase
      desc "Suspend a running Vagrant environment."
      register "suspend"

      def execute
        target_vms.each do |vm|
          if vm.created?
            vm.suspend
          else
            vm.env.ui.info "VM not created. Moving on..."
          end
        end
      end
    end
  end
end
