module Vagrant
  module Actions
    module VM
      class Stop < Base
        def execute!
          logger.info "Forcing shutdown of VM..."
          @vm.vm.stop(true)
        end
      end
    end
  end
end