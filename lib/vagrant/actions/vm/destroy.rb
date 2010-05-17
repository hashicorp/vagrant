module Vagrant
  module Actions
    module VM
      class Destroy < Base
        def execute!
          @runner.invoke_around_callback(:destroy) do
            destroy_vm
            update_dotfile
          end
        end

        def destroy_vm
          logger.info "Destroying VM and associated drives..."
          @runner.vm.destroy(:destroy_medium => :delete)
          @runner.vm = nil
        end

        def update_dotfile
          @runner.env.update_dotfile
        end
      end
    end
  end
end
