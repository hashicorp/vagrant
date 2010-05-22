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
        all_or_single(args, :destroy)
      end

      # Destroys a single VM by name.
      def destroy_single(name)
        vm = env.vms[name.to_sym]
        if vm.nil?
          error_and_exit(:unknown_vm, :vm => name)
          return # for tests
        end

        if vm.created?
          vm.destroy
        else
          vm.env.logger.info "VM '#{name}' not created. Ignoring."
        end
      end

      def options_spec(opts)
        opts.banner = "Usage: vagrant destroy"
      end
    end
  end
end
