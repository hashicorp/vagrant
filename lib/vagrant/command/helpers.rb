module Vagrant
  module Command
    module Helpers
      # Initializes the environment by pulling the environment out of
      # the configuration hash and sets up the UI if necessary.
      def initialize_environment(args, options, config)
        raise Errors::CLIMissingEnvironment.new if !config[:env]
        @env = config[:env]
      end

      # This returns an array of {VM} objects depending on the arguments
      # given to the command.
      def target_vms(name=nil)
        raise Errors::NoEnvironmentError.new if !env.root_path

        name ||= self.name rescue nil

        @target_vms ||= begin
          if env.multivm?
            return env.vms.values if !name
            vm = env.vms[name.to_sym]
            raise Errors::VMNotFoundError.new(:name => name) if !vm
          else
            raise Errors::MultiVMEnvironmentRequired.new if name
            vm = env.vms.values.first
          end

          [vm]
        end
      end
    end
  end
end
