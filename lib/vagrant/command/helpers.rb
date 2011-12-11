module Vagrant
  module Command
    module Helpers
      # Initializes the environment by pulling the environment out of
      # the configuration hash and sets up the UI if necessary.
      def initialize_environment(args, options, config)
        raise Errors::CLIMissingEnvironment if !config[:env]
        @env = config[:env]
      end

      # This returns an array of {VM} objects depending on the arguments
      # given to the command.
      def target_vms(name=nil)
        raise Errors::NoEnvironmentError if !env.root_path

        name ||= self.name rescue nil

        @target_vms ||= begin
          if env.multivm?
            return env.vms_ordered if !name
            vm = env.vms[name.to_sym]
            raise Errors::VMNotFoundError, :name => name if !vm
          else
            raise Errors::MultiVMEnvironmentRequired if name
            vm = env.vms.values.first
          end

          [vm]
        end
      end

      # This will yield for each target VM to the command. The VM is guaranteed
      # to be loaded on each iteration.
      def with_target_vms
        target_vms.each do |old_vm|
          # We get a new VM here to avoid potentially stale VMs
          vm = env.vms[old_vm.name]
          yield vm
        end
      end
    end
  end
end
