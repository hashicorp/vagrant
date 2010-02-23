module Vagrant
  module Actions
    module VM
      class Import < Base
        def execute!
          @runner.invoke_around_callback(:import) do
            Busy.busy do
              logger.info "Importing base VM (#{Vagrant.config[:vm][:base]})..."
              # Use the first argument passed to the action
              @runner.vm = VirtualBox::VM.import(Vagrant.config[:vm][:base])
            end
          end
        end
      end
    end
  end
end
