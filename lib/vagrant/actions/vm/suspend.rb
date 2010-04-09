module Vagrant
  module Actions
    module VM
      class Suspend < Base
        def execute!
          if !@runner.vm.running?
            raise ActionException.new(:vm_not_running_for_suspend)
          end

          logger.info "Saving VM state and suspending execution..."
          @runner.vm.save_state
        end
      end
    end
  end
end
