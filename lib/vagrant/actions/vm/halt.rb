module Vagrant
  module Actions
    module VM
      class Halt < Base
        def execute!
          raise ActionException.new(:vm_not_running) unless @runner.vm.running?

          @runner.invoke_around_callback(:halt) do
            @runner.system.halt if !options[:force]

            if @runner.vm.state(true) != :powered_off
              logger.info "Forcing shutdown of VM..."
              @runner.vm.stop
            end
          end
        end

        def force?
          !!options[:force]
        end
      end
    end
  end
end
