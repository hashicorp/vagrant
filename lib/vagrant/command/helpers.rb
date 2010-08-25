module Vagrant
  module Command
    module Helpers
      def require_environment
        raise NoEnvironmentError.new("No Vagrant environment detected. Run `vagrant init` to set one up.") if !env.root_path
      end

      # This returns an array of {VM} objects depending on the arguments
      # given to the command.
      def target_vms
        require_environment

        @target_vms ||= begin
          if env.multivm?
            return env.vms.values if !self.name
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
end
