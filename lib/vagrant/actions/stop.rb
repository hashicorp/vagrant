module Vagrant
  module Actions
    class Stop < Base
      def execute!
        logger.info "Forcing shutdown of VM..."
        @vm.vm.stop(true)
      end
    end
  end
end