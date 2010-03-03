module Vagrant
  module Actions
    module VM
      class Halt < Base
        def execute!
          logger.info "Forcing shutdown of VM..."
          @runner.vm.stop(true)
        end
      end
    end
  end
end
