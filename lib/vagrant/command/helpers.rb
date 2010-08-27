module Vagrant
  module Command
    module Helpers
      # Initializes the environment by pulling the environment out of
      # the configuration hash and sets up the UI if necessary.
      def initialize_environment(args, options, config)
        raise Errors::CLIMissingEnvironment.new if !config[:env]
        @env = config[:env]
        @env.ui = UI::Shell.new(@env, shell) if !@env.ui.is_a?(UI::Shell)
      end

      def require_environment
        raise Errors::NoEnvironmentError.new if !env.root_path
      end

      # This returns an array of {VM} objects depending on the arguments
      # given to the command.
      def target_vms
        require_environment

        @target_vms ||= begin
          if env.multivm?
            return env.vms.values if !self.name
            vm = env.vms[self.name.to_sym]
            raise Errors::VMNotFoundError.new(:name => self.name) if !vm
          else
            raise Errors::MultiVMEnvironmentRequired.new if self.name
            vm = env.vms.values.first
          end

          [vm]
        end
      end
    end
  end
end
