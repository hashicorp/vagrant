module Vagrant
  class Commands
    # Reload the environment. This is almost equivalent to the {up} command
    # except that it doesn't import the VM and do the initialize bootstrapping
    # of the instance. Instead, it forces a shutdown (if its running) of the
    # VM, updates the metadata (shared folders, forwarded ports), restarts
    # the VM, and then reruns the provisioning if enabled.
    class Reload < Base
      Base.subcommand "reload", self
      description "Reload the vagrant environment"

      def execute(args=[])
        env.require_persisted_vm
        env.vm.execute!(Actions::VM::Reload)
      end

      def options_spec(opts)
        opts.banner = "Usage: vagrant reload"
      end
    end
  end
end