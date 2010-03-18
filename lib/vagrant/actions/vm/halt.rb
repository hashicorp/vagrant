module Vagrant
  module Actions
    module VM
      class Halt < Base
        def execute!
          raise ActionException.new(:vm_not_running) unless @runner.vm.running?

          logger.info "Forcing shutdown of VM..."
          @runner.vm.stop(true)
        end
      end
    end
  end
end
