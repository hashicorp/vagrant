module Vagrant
  class Commands
    # Halts a running vagrant instance. This forcibly halts the instance;
    # it is the equivalent of pulling the power on a machine. The instance
    # can be restarted again with {up}.
    #
    # This command requires than an instance already be brought up with
    # `vagrant up`.
    class Halt < Base
      Base.subcommand "halt", self
      description "Halts the currently running vagrant environment"

      def execute(args=[])
        args = parse_options(args)

        if args[0]
          halt_single(args[0])
        else
          halt_all
        end
      end

      def halt_single(name)
        vm = env.vms[name.to_sym]
        if vm.nil?
          error_and_exit(:unknown_vm, :vm => name)
          return # for tests
        end

        if vm.created?
          vm.halt(options[:force])
        else
          logger.info "VM '#{name}' not created. Ignoring."
        end
      end

      def halt_all
        env.vms.keys.each do |name|
          halt_single(name)
        end
      end

      def options_spec(opts)
        opts.banner = "Usage: vagrant halt"

        # Defaults
        options[:force] = false

        opts.on("-f", "--force", "Forceful shutdown of virtual machine.") do |v|
          options[:force] = true
        end
      end
    end
  end
end
