module Vagrant
  module Actions
    class Import < Base
      def execute!
        @vm.invoke_callback(:before_import)

        Busy.busy do
          logger.info "Importing base VM (#{Vagrant.config[:vm][:base]})..."
          @vm.vm = VirtualBox::VM.import(File.expand_path(Vagrant.config[:vm][:base]))
        end

        @vm.invoke_callback(:after_import)
      end
    end
  end
end