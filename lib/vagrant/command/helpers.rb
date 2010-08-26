module Vagrant
  module Command
    module Helpers
      # Initializes the environment by pulling the environment out of
      # the configuration hash and sets up the UI if necessary.
      def initialize_environment(args, options, config)
        raise CLIMissingEnvironment.new("This command requires that a Vagrant environment be properly passed in as the last parameter.") if !config[:env]
        @env = config[:env]
        @env.ui = UI::Shell.new(@env, shell) if !@env.ui.is_a?(UI::Shell)
      end

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
