module Vagrant
  module Actions
    module VM
      class Down < Base
        def prepare
          @runner.add_action(Halt) if @runner.vm.running?
          @runner.add_action(Destroy)
        end
      end
    end
  end
end
