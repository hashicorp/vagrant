module Vagrant
  module Actions
    class Import < Base
      #First arg should be the ovf_file location for import
      def initialize(vm, *args)
        super vm
        @ovf_file = args[0]
      end

      def execute!
        @vm.invoke_around_callback(:import) do
          Busy.busy do
            logger.info "Importing base VM (#{Vagrant.config[:vm][:base]})..."
            # Use the first argument passed to the action
            @vm.vm = VirtualBox::VM.import(@ovf_file || File.expand_path(Vagrant.config[:vm][:base]))
          end
        end
      end
    end
  end
end
