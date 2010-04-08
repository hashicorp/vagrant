module Vagrant
  module Actions
    module VM
      class Destroy < Base
        def execute!
          @runner.invoke_around_callback(:destroy) do
            destroy_vm
            depersist
          end
        end

        def destroy_vm
          logger.info "Destroying VM and associated drives..."
          @runner.vm.destroy(:destroy_medium => :delete)
        end

        def depersist
          @runner.env.depersist_vm
        end
      end
    end
  end
end
