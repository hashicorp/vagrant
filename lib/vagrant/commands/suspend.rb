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
        args = parse_options(args)

        if args[0]
          suspend_single(args[0])
        else
          suspend_all
        end
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

      def suspend_all
        env.vms.keys.each do |name|
          suspend_single(name)
        end
      end

      def options_spec(opts)
        opts.banner = "Usage: vagrant suspend"
      end
    end
  end
end
