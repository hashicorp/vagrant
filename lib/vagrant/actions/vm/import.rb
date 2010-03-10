module Vagrant
  module Actions
    module VM
      class Import < Base
        def execute!
          @runner.invoke_around_callback(:import) do
            Busy.busy do
              logger.info "Importing base VM (#{Vagrant::Env.box.ovf_file})..."
              # Use the first argument passed to the action
              @runner.vm = VirtualBox::VM.import(Vagrant::Env.box.ovf_file)
              raise ActionException.new("The VM import failed! Try running `VBoxManage import` on the box file manually for more verbose error output.") unless @runner.vm
            end
          end
        end
      end
    end
  end
end
