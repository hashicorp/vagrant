module Vagrant
  module Actions
    module VM
      class Destroy < Base
        def execute!
          @runner.invoke_around_callback(:destroy) do
            logger.info "Destroying VM and associated drives..."
            @runner.vm.destroy(:destroy_image => true)
          end
        end
      end
    end
  end
end
