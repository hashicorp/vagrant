module Vagrant
  module Actions
    module VM
      class Customize < Base
        def execute!
          logger.info "Running any VM customizations..."

          # Run the customization procs over the VM
          Vagrant.config.vm.run_procs!(@runner.vm)

          # Save the vm
          @runner.vm.save(true)
        end
      end
    end
  end
end
