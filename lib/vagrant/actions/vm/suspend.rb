module Vagrant
  module Actions
    module VM
      class Suspend < Base
        def execute!
          if !@runner.vm.running?
            raise ActionException.new("The vagrant virtual environment you are trying to suspend must be running to be suspended.")
          end

          logger.info "Saving VM state and suspending execution..."
          @runner.vm.save_state(true)
        end
      end
    end
  end
end
