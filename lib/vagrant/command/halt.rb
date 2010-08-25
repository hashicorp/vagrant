module Vagrant
  module Command
    class HaltCommand < NamedBase
      desc "Halt the running VMs in the environment"
      class_option :force, :type => :boolean, :default => false, :aliases => "-f"
      register "halt"

      def execute
        target_vms.each do |vm|
          if vm.created?
            vm.halt(options)
          else
            vm.env.ui.info "VM not created. Moving on..."
          end
        end
      end
    end
  end
end
