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
        args = parse_options(args)
        ssh_connect(args[0])
      end

      def ssh_connect(name)
        if name.nil? && env.multivm?
          error_and_exit(:ssh_multivm)
          return # for tests
        end

        vm = name.nil? ? env.vms.values.first :  env.vms[name.to_sym]
        if vm.nil?
          error_and_exit(:unknown_vm, :vm => name)
          return # for tests
        end

        if !vm.created?
          error_and_exit(:environment_not_created)
          return
        else
          vm.ssh.connect
        end
      end

      def options_spec(opts)
        opts.banner = "Usage: vagrant ssh"
      end
    end
  end
end
