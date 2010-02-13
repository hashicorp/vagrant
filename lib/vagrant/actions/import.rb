module Vagrant
  module Actions
    class Import < Base
      def execute!
        logger.info "Importing base VM (#{Vagrant.config[:vm][:base]})..."
        @vm.vm = VirtualBox::VM.import(File.expand_path(Vagrant.config[:vm][:base]))
      end
    end
  end
end