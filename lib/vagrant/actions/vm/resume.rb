module Vagrant
  module Actions
    module VM
      class Resume < Base
        def execute!
          if !@runner.vm.saved?
            raise ActionException.new(:vm_not_suspended)
          end

          logger.info "Resuming suspended VM..."
          @runner.start
        end
      end
    end
  end
end
