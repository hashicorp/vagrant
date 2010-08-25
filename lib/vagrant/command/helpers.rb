module Vagrant
  module Command
    module Helpers
      # This returns an array of {VM} objects depending on the arguments
      # given to the command.
      def target_vms
        if env.multivm?
          return env.vms if !self.name
          vm = env.vms[self.name.to_sym]
          raise VMNotFoundError.new("A VM by the name of `#{self.name}` was not found.") if !vm
        else
          raise MultiVMEnvironmentRequired.new("A multi-vm environment is required for name specification to a command.") if self.name
          vm = env.vms.values.first
        end

        [vm]
      end
    end
  end
end
