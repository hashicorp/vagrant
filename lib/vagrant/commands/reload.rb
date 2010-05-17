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
        args = parse_options(args)

        if args[0]
          reload_single(args[0])
        else
          reload_all
        end
      end

      def reload_single(name)
        vm = env.vms[name.to_sym]
        if vm.nil?
          error_and_exit(:unknown_vm, :vm => name)
          return # for tests
        end

        if vm.created?
          vm.reload
        else
          logger.info "VM '#{name}' not created. Ignoring."
        end
      end

      def reload_all
        env.vms.keys.each do |name|
          reload_single(name)
        end
      end

      def options_spec(opts)
        opts.banner = "Usage: vagrant reload"
      end
    end
  end
end
