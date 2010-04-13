module Vagrant
  class Commands
    # Destroys a vagrant instance. This not only shuts down the instance
    # (if its running), but also deletes it from the system, including the
    # hard disks associated with it.
    #
    # This command requires that an instance already be brought up with
    # `vagrant up`.
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