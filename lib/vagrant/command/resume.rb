module Vagrant
  module Command
    class ResumeCommand < Base
      desc "Resume a suspended Vagrant environment."
      register "resume"

      def execute
        target_vms.each do |vm|
          if vm.created?
            vm.resume
          else
            vm.env.ui.info "VM not created. Moving on..."
          end
        end
      end
    end
  end
end
