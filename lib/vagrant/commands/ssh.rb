module Vagrant
  class Commands
    # Reload the environment. This is almost equivalent to the {up} command
    # except that it doesn't import the VM and do the initialize bootstrapping
    # of the instance. Instead, it forces a shutdown (if its running) of the
    # VM, updates the metadata (shared folders, forwarded ports), restarts
    # the VM, and then reruns the provisioning if enabled.
    class SSH < Base
      Base.subcommand "ssh", self
      description "SSH into the currently running environment"

      def execute(args=[])
        env.require_persisted_vm
        env.ssh.connect
      end

      def options_spec(opts)
        opts.banner = "Usage: vagrant ssh"
      end
    end
  end
end