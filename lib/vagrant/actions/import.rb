module Vagrant
  module Actions
    class Import < Base
      def execute!
        @vm.invoke_around_callback(:import) do
          Busy.busy do
            logger.info "Importing base VM (#{Vagrant.config[:vm][:base]})..."
            @vm.vm = VirtualBox::VM.import(File.expand_path(Vagrant.config[:vm][:base]))
          end
        end
      end
    end
  end
end
