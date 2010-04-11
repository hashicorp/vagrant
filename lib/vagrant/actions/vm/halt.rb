module Vagrant
  module Actions
    module VM
      class Halt < Base
        def execute!
          raise ActionException.new(:vm_not_running) unless @runner.vm.running?

          @runner.invoke_around_callback(:halt) do
            logger.info "Forcing shutdown of VM..."
            @runner.vm.stop
          end
        end
      end
    end
  end
end
