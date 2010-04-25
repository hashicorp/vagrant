module Vagrant
  module Actions
    module VM
      class Halt < Base
        attr_reader :force

        def initialize(vm, force=nil)
          super
          @force = force
        end

        def execute!
          raise ActionException.new(:vm_not_running) unless @runner.vm.running?

          @runner.invoke_around_callback(:halt) do
            @runner.system.halt if !force

            if @runner.vm.state(true) != :powered_off
              logger.info "Forcing shutdown of VM..."
              @runner.vm.stop
            end
          end
        end
      end
    end
  end
end
