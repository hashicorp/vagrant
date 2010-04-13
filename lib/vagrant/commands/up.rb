module Vagrant
  class Commands
    class Up < Base
      Base.subcommand "up", self
      description "Creates the vagrant environment"

      def execute(args=[])
        if env.vm
          logger.info "VM already created. Starting VM if its not already running..."
          env.vm.start
        else
          env.require_box
          env.create_vm.execute!(Actions::VM::Up)
        end
      end

      def options_spec(opts)
        opts.banner = "Usage: vagrant up"
      end
    end
  end
end