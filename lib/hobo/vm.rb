module Hobo
  class VM
    HD_EXT_DEFAULT = 'VMDK'
    attr_reader :vm

    extend Hobo::Util
    include Hobo::Util

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
The hobo virtual environment you are trying to suspend is already in a
suspended state.
error
        logger.info "Saving VM state..."
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
      move_hd if Hobo.config[:vm][:hd_location]
      persist
      setup_mac_address
      forward_ports
      setup_shared_folder
      start
      mount_shared_folder
    end

    def destroy
      if @vm.running?
        logger.info "VM is running. Forcing immediate shutdown..."
        @vm.stop(true)
      end

      logger.info "Destroying VM and associated drives..."
      @vm.destroy(:destroy_image => true)
    end

    def move_hd
      error_and_exit(<<-error) unless @vm.powered_off?
The virtual machine must be powered off to move its disk.
error

      old_image = hd.image.dup
      new_image_file = Hobo.config[:vm][:hd_location] + old_image.filename

      logger.info "Cloning current VM Disk to new location (#{ new_image_file })..."
      # TODO image extension default?
      new_image = hd.image.clone(new_image_file , HD_EXT_DEFAULT, true)
      hd.image = new_image
      
      logger.info "Attaching new disk to VM ..."
      @vm.save

      logger.info "Destroying old VM Disk (#{ old_image.filename })..."
      old_image.destroy(true)
    end

    def import
      logger.info "Importing base VM (#{Hobo.config[:vm][:base]})..."
      @vm = VirtualBox::VM.import(File.expand_path(Hobo.config[:vm][:base]))
    end

    def persist
      logger.info "Persisting the VM UUID (#{@vm.uuid})..."
      Env.persist_vm(@vm)
    end

    def setup_mac_address
      logger.info "Matching MAC addresses..."
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
      logger.info "Creating shared folders..."
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
      logger.info "Booting VM..."
      @vm.start(:headless, true)

      # Now we have to wait for the boot to be successful
      logger.info "Waiting for VM to boot..."
      
      Hobo.config[:ssh][:max_tries].to_i.times do |i|
        sleep 5 unless ENV['HOBO_ENV'] == 'test'
        logger.info "Trying to connect (attempt ##{i+1} of #{Hobo.config[:ssh][:max_tries]})..."

        if Hobo::SSH.up?
          logger.info "VM booted and ready for use!"
          return true
        end
      end

      logger.info "Failed to connect to VM! Failed to boot?"
      false
    end

    def saved?; @vm.saved? end

    def save_state(errs); @vm.save_state(errs) end

    # TODO need a better way to which controller is the hd
    def hd; @vm.storage_controllers.first.devices.first end
  end
end
