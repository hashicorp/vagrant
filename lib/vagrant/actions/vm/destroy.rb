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
          @runner.vm.destroy(:destroy_image => true)
        end

        def depersist
          Env.depersist_vm(@runner)
        end
      end
    end
  end
end
