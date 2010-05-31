module Vagrant
  module Actions
    module VM
      class Down < Base
        def prepare
          # The true as the 2nd parameter always forces the shutdown so its
          # fast (since we're destroying anyways)
          @runner.add_action(Halt, :force => true) if @runner.vm.running?
          @runner.add_action(Destroy)
        end

        def after_halt
          # This sleep is necessary to wait for the VM to clean itself up.
          # There appears to be nothing in the API that does this "wait"
          # for us.
          Kernel.sleep(1)
        end
      end
    end
  end
end
