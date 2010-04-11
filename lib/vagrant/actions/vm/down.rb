module Vagrant
  module Actions
    module VM
      class Down < Base
        def prepare
          @runner.add_action(Halt) if @runner.vm.running?
          @runner.add_action(Destroy)
        end

        def after_halt
          # This sleep is necessary to wait for the GUI to clean itself up.
          # There appears to be nothing in the API that does this "wait"
          # for us.
          Kernel.sleep(1) if @runner.env.config.vm.boot_mode == "gui"
        end
      end
    end
  end
end
