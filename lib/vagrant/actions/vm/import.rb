module Vagrant
  module Actions
    module VM
      class Import < Base
        def execute!
          @runner.invoke_around_callback(:import) do
            Busy.busy do
              logger.info "Importing base VM (#{@runner.env.box.ovf_file})..."
              # Use the first argument passed to the action
              @runner.vm = VirtualBox::VM.import(@runner.env.box.ovf_file)
              raise ActionException.new(:virtualbox_import_failure) unless @runner.vm
            end
          end
        end
      end
    end
  end
end
