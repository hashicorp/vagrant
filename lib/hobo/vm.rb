module Hobo
  class VM
    class <<self
      # Bring up the virtual machine. Imports the base image and
      # provisions it.
      def up
        HOBO_LOGGER.info "Importing base VM (#{Hobo.config[:vm][:base]})..."
        vm = VirtualBox::VM.import(File.expand_path(Hobo.config[:vm][:base]))
    
        HOBO_LOGGER.info "Persisting the VM UUID (#{vm.uuid})..."
        # TODO: persist it! dot file in the root (where Hobofile is)
      end
    end
  end
end