module Hobo
  class VM
    attr_reader :vm

    extend Hobo::Error

    class << self
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


      # Save the state of the current hobo environment to disk
      def suspend
        Env.require_persisted_vm
        error_and_exit(<<-error) if Env.persisted_vm.saved?
The hobo virtual environment you are trying to resume is already in a
suspended state.
error
        Env.persisted_vm.save_state(true)
      end

      # Resume the current hobo environment from disk
      def resume
        Env.require_persisted_vm
        error_and_exit(<<-error) unless Env.persisted_vm.saved?
The hobo virtual environment you are trying to resume is not in a
suspended state.
error
        Env.persisted_vm.start
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
      forward_ports
      setup_shared_folder
      start
      mount_shared_folder
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

    def forward_ports
      HOBO_LOGGER.info "Forwarding ports..."

      Hobo.config.vm.forwarded_ports.each do |name, options|
        HOBO_LOGGER.info "Forwarding \"#{name}\": #{options[:guestport]} => #{options[:hostport]}"
        port = VirtualBox::ForwardedPort.new
        port.name = name
        port.hostport = options[:hostport]
        port.guestport = options[:guestport]
        @vm.forwarded_ports << port
      end

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

    def mount_shared_folder
      HOBO_LOGGER.info "Mounting shared folders..."
      Hobo::SSH.execute do |ssh|
        ssh.exec!("sudo mkdir -p #{Hobo.config.vm.project_directory}")
        ssh.exec!("sudo mount -t vboxsf hobo-root-path #{Hobo.config.vm.project_directory}")
      end
    end

    def start
      HOBO_LOGGER.info "Booting VM..."
      @vm.start(:headless, true)

      # Now we have to wait for the boot to be successful
      HOBO_LOGGER.info "Waiting for VM to boot..."

      Hobo.config[:ssh][:max_tries].to_i.times do |i|
        sleep 5 unless ENV['HOBO_ENV'] == 'test'
        HOBO_LOGGER.info "Trying to connect (attempt ##{i+1} of #{Hobo.config[:ssh][:max_tries]})..."

        if Hobo::SSH.up?
          HOBO_LOGGER.info "VM booted and ready for use!"
          return true
        end
      end

      HOBO_LOGGER.info "Failed to connect to VM! Failed to boot?"
      false
    end

    def saved?; @vm.saved? end

    def save_state(errs); @vm.save_state(errs) end
  end
end
