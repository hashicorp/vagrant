module Vagrant
  class Commands
    # Suspend a running vagrant instance. This suspends the instance, saving
    # the state of the VM and "pausing" it. The instance can be resumed
    # again with {resume}.
    #
    # This command requires that an instance already be brought up with
    # `vagrant up`.
    class Suspend < Base
      Base.subcommand "suspend", self
      description "Suspends the currently running vagrant environment"

      def execute(args=[])
        all_or_single(args, :suspend)
      end

      def suspend_single(name)
        vm = env.vms[name.to_sym]
        if vm.nil?
          error_and_exit(:unknown_vm, :vm => name)
          return # for tests
        end

        if vm.created?
          vm.suspend
        else
          vm.env.logger.info "VM '#{name}' not created. Ignoring."
        end
      end

      def options_spec(opts)
        opts.banner = "Usage: vagrant suspend"
      end
    end
  end
end
