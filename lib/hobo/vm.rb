module Hobo
  class VM
    class <<self
      # Bring up the virtual machine. Imports the base image and
      # provisions it.
      def up
        vm = import
        persist_vm(vm)
        setup_mac_address(vm)
        forward_ssh(vm)
        setup_shared_folder(vm)
      end

      def import
        HOBO_LOGGER.info "Importing base VM (#{Hobo.config[:vm][:base]})..."
        VirtualBox::VM.import(File.expand_path(Hobo.config[:vm][:base]))
      end

      def persist_vm(vm)
        HOBO_LOGGER.info "Persisting the VM UUID (#{vm.uuid})..."
        Env.persist_vm(vm)
      end

      def setup_mac_address(vm)
        HOBO_LOGGER.info "Matching MAC addresses..."
        vm.nics.first.macaddress = Hobo.config[:vm][:base_mac]
        vm.save(true)
      end

      def forward_ssh(vm)
        HOBO_LOGGER.info "Forwarding SSH ports..."
        port = VirtualBox::ForwardedPort.new
        port.name = "ssh"
        port.hostport = Hobo.config[:ssh][:port]
        port.guestport = 22
        vm.forwarded_ports << port
        vm.save(true)
      end

      # TODO: We need to get the host path.
      def setup_shared_folder(vm)
        HOBO_LOGGER.info "Creating shared folders..."
        folder = VirtualBox::SharedFolder.new
        folder.name = "project-path"
        folder.hostpath = ""
        vm.shared_folders << folder
        #vm.save(true)
      end
    end
  end
end