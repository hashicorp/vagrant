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
        env.require_persisted_vm
        env.vm.suspend
      end

      def options_spec(opts)
        opts.banner = "Usage: vagrant suspend"
      end
    end
  end
end