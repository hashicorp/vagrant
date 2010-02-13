module Vagrant
  class VM
    include Vagrant::Util
    attr_accessor :vm
    attr_reader :actions

    class << self
      # Bring up the virtual machine. Imports the base image and
      # provisions it.
      def up
        new.create
      end

      # Finds a virtual machine by a given UUID and either returns
      # a Vagrant::VM object or returns nil.
      def find(uuid)
        vm = VirtualBox::VM.find(uuid)
        return nil if vm.nil?
        new(vm)
      end
    end

    def initialize(vm=nil)
      @vm = vm
      @actions = []
    end

    def execute!
      # Initialize each action. Prepare is not done together with
      # this since initialization is a time which guarantees that
      # prepare has not been called for any other action yet.
      @actions.collect! do |action_class|
        action_class.new(self)
      end

      # Call the prepare method on each once its
      # initialized, then call the execute! method
      [:prepare, :execute!].each do |method|
        @actions.each do |action|
          action.send(method)
        end
      end
    end

    def invoke_callback(name, *args)
      # Attempt to call the method for the callback on each of the
      # actions
      @actions.each do |action|
        action.send(name, *args) if action.respond_to?(name)
      end
    end

    def create
      share_folder("vagrant-root", Env.root_path, Vagrant.config.vm.project_directory)

      # Create the provisioning object, prior to doing anything so it can
      # set any configuration on the VM object prior to creation
      provisioning = Provisioning.new(self)

      # The path of righteousness
      import
      move_hd if Vagrant.config[:vm][:hd_location]
      persist
      setup_mac_address
      forward_ports
      setup_shared_folders
      start
      mount_shared_folders

      # Once we're started, run the provisioning
      provisioning.run
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
      new_image_file = Vagrant.config[:vm][:hd_location] + old_image.filename

      logger.info "Cloning current VM Disk to new location (#{ new_image_file })..."
      # TODO image extension default?
      new_image = hd.image.clone(new_image_file , Vagrant.config[:vm][:disk_image_format], true)
      hd.image = new_image

      logger.info "Attaching new disk to VM ..."
      @vm.save

      logger.info "Destroying old VM Disk (#{ old_image.filename })..."
      old_image.destroy(true)
    end

    def import
      logger.info "Importing base VM (#{Vagrant.config[:vm][:base]})..."
      @vm = VirtualBox::VM.import(File.expand_path(Vagrant.config[:vm][:base]))
    end

    def persist
      logger.info "Persisting the VM UUID (#{@vm.uuid})..."
      Env.persist_vm(@vm)
    end

    def setup_mac_address
      logger.info "Matching MAC addresses..."
      @vm.nics.first.macaddress = Vagrant.config[:vm][:base_mac]
      @vm.save(true)
    end

    def forward_ports
      logger.info "Forwarding ports..."

      Vagrant.config.vm.forwarded_ports.each do |name, options|
        logger.info "Forwarding \"#{name}\": #{options[:guestport]} => #{options[:hostport]}"
        port = VirtualBox::ForwardedPort.new
        port.name = name
        port.hostport = options[:hostport]
        port.guestport = options[:guestport]
        @vm.forwarded_ports << port
      end

      @vm.save(true)
    end

    def setup_shared_folders
      logger.info "Creating shared folders metadata..."

      shared_folders.each do |name, hostpath, guestpath|
        folder = VirtualBox::SharedFolder.new
        folder.name = name
        folder.hostpath = hostpath
        @vm.shared_folders << folder
      end

      @vm.save(true)
    end

    def mount_shared_folders
      logger.info "Mounting shared folders..."

      Vagrant::SSH.execute do |ssh|
        shared_folders.each do |name, hostpath, guestpath|
          logger.info "-- #{name}: #{guestpath}"
          ssh.exec!("sudo mkdir -p #{guestpath}")
          ssh.exec!("sudo mount -t vboxsf #{name} #{guestpath}")
          ssh.exec!("sudo chown #{Vagrant.config.ssh.username} #{guestpath}")
        end
      end
    end

    def start(sleep_interval = 5)
      logger.info "Booting VM..."
      @vm.start(:headless, true)

      # Now we have to wait for the boot to be successful
      logger.info "Waiting for VM to boot..."

      Vagrant.config[:ssh][:max_tries].to_i.times do |i|
        logger.info "Trying to connect (attempt ##{i+1} of #{Vagrant.config[:ssh][:max_tries]})..."

        if Vagrant::SSH.up?
          logger.info "VM booted and ready for use!"
          return true
        end

        sleep sleep_interval
      end

      logger.info "Failed to connect to VM! Failed to boot?"
      false
    end

    def shared_folders(clear=false)
      @shared_folders = nil if clear
      @shared_folders ||= []
    end

    def share_folder(name, hostpath, guestpath)
      shared_folders << [name, hostpath, guestpath]
    end

    def saved?
      @vm.saved?
    end

    def save_state
      logger.info "Saving VM state..."
      @vm.save_state(true)
    end

    # TODO the longest method, needs to be split up
    def package(name, to)
      folder = FileUtils.mkpath(File.join(to, name))
      logger.info "Creating working directory: #{folder} ..."

      ovf_path = File.join(folder, "#{name}.ovf")
      tar_path = "#{folder}.box"

      logger.info "Exporting required VM files to working directory ..."
      @vm.export(ovf_path)

      # TODO use zlib ...
      logger.info "Packaging VM into #{name}.box ..."
      Tar.open(tar_path, File::CREAT | File::WRONLY, 0644, Tar::GNU) do |tar|
        begin
          # appending the expanded file path adds the whole folder tree
          # to the tar archive there must be a better way
          working_dir = FileUtils.pwd
          FileUtils.cd(to)
          tar.append_tree(name)
        ensure
          FileUtils.cd(working_dir)
        end
      end

      logger.info "Removing working directory ..."
      FileUtils.rm_r(folder)

      tar_path
    end

    # TODO need a better way to which controller is the hd
    def hd
      @vm.storage_controllers.first.devices.first
    end

    def powered_off?; @vm.powered_off? end

    def export(filename); @vm.export(filename, {}, true) end
  end
end
