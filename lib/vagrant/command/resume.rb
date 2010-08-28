module Vagrant
  module Command
    class ResumeCommand < NamedBase
      desc "Resume a suspended Vagrant environment."
      register "resume"

      def execute
        target_vms.each do |vm|
          if vm.created?
            vm.resume
          else
            vm.env.ui.info "vagrant.commands.common.vm_not_created"
          end
        end
      end
    end
  end
end
