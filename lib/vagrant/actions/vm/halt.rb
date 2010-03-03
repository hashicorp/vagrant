module Vagrant
  module Actions
    module VM
      class Halt < Base
        def execute!
          raise ActionException.new("VM is not running! Nothing to shut down!") unless @runner.vm.running?

          logger.info "Forcing shutdown of VM..."
          @runner.vm.stop(true)
        end
      end
    end
  end
end
