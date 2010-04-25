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
        parse_options(args)

        env.require_persisted_vm
        env.vm.execute!(Actions::VM::Halt, options[:force])
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