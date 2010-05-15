module Vagrant
  class Commands
    # Bring up a vagrant instance. This handles everything from importing
    # the base VM, setting up shared folders, forwarded ports, etc to
    # provisioning the instance with chef. {up} also starts the instance,
    # running it in the background.
    class Up < Base
      Base.subcommand "up", self
      description "Creates the vagrant environment"

      def execute(args=[])
        # First verify that all VMs have valid boxes
        env.vms.each { |name, vm| vm.env.require_box unless vm.created? }

        # Next, handle each VM
        env.vms.each do |name, vm|
          if vm.created?
            logger.info "VM '#{name}' already created. Booting if its not already running..."
            # vm.start
          else
            logger.info "Creating VM '#{name}'"
            # env.create_vm.execute!(Actions::VM::Up)
          end
        end
      end

      def options_spec(opts)
        opts.banner = "Usage: vagrant up"
      end
    end
  end
end
