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

      # SSHs into the VM and replaces the ruby process with the SSH process
      def ssh
        Env.require_persisted_vm
        SSH.connect
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
      start
    end

    def destroy
      if @vm.running?
        HOBO_LOGGER.info "VM is running. Forcing immediate shutdown..."
        @vm.stop(true)
      end

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

    def setup_shared_folder
      HOBO_LOGGER.info "Creating shared folders..."
      folder = VirtualBox::SharedFolder.new
      folder.name = "hobo-root-path"
      folder.hostpath = Env.root_path
      @vm.shared_folders << folder
      @vm.save(true)
    end

    def start
      HOBO_LOGGER.info "Booting VM..."
      @vm.start(:headless, true)

      # Now we have to wait for the boot to be successful
      # TODO
    end
  end
end