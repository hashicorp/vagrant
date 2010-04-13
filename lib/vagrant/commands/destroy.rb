module Vagrant
  class Commands
    class Destroy < Base
      Base.subcommand "destroy", self
      description "Destroys the vagrant environment"

      def execute(args=[])
        env.require_persisted_vm
        env.vm.destroy
      end

      def options_spec(opts)
        opts.banner = "Usage: vagrant destroy"
      end
    end
  end
end