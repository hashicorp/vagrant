module Vagrant
  module Actions
    class Import < Base
      attr_accessor :ovf_file
      #First arg should be the ovf_file location for import
      def initialize(vm, *args)
        super vm
        @ovf_file = File.expand_path(args[0] || Vagrant.config[:vm][:base])
      end

      def execute!
        @vm.invoke_around_callback(:import) do
          Busy.busy do
            logger.info "Importing base VM (#{@ovf_file})..."
            # Use the first argument passed to the action
            @vm.vm = VirtualBox::VM.import(@ovf_file)
          end
        end
      end
    end
  end
end
