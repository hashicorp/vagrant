module Hobo
  class VM
    attr_reader :vm

    class <<self
      # Bring up the virtual machine. Imports the base image and
      # provisions it.
      def up
        new.create
      end

      # Tear down a virtual machine.
      def down
        Env.require_persisted_vm
        Env.persisted_vm.destroy
      end

      # Finds a virtual machine by a given UUID and either returns
      # a Hobo::VM object or returns nil.
      def find(uuid)
        vm = VirtualBox::VM.find(uuid)
        return nil if vm.nil?
        new(vm)
      end
    end

    def initialize(vm=nil)
      @vm = vm
    end

    def create
      import
      persist
      setup_mac_address
      forward_ssh
      setup_shared_folder
    end

    def destroy
      HOBO_LOGGER.info "Destroying VM and associated drives..."
      @vm.destroy(:destroy_image => true)
    end

    def import
      HOBO_LOGGER.info "Importing base VM (#{Hobo.config[:vm][:base]})..."
      @vm = VirtualBox::VM.import(File.expand_path(Hobo.config[:vm][:base]))
    end

    def persist
      HOBO_LOGGER.info "Persisting the VM UUID (#{@vm.uuid})..."
      Env.persist_vm(@vm)
    end

    def setup_mac_address
      HOBO_LOGGER.info "Matching MAC addresses..."
      @vm.nics.first.macaddress = Hobo.config[:vm][:base_mac]
      @vm.save(true)
    end

    def forward_ssh
      HOBO_LOGGER.info "Forwarding SSH ports..."
      port = VirtualBox::ForwardedPort.new
      port.name = "ssh"
      port.hostport = Hobo.config[:ssh][:port]
      port.guestport = 22
      @vm.forwarded_ports << port
      @vm.save(true)
    end

    # TODO: We need to get the host path.
    def setup_shared_folder
      HOBO_LOGGER.info "Creating shared folders..."
      folder = VirtualBox::SharedFolder.new
      folder.name = "project-path"
      folder.hostpath = ""
      @vm.shared_folders << folder
      #vm.save(true)
    end
  end
end