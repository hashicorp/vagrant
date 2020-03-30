require "log4r"
require "fileutils"
require "vagrant/util/numeric"
require "vagrant/util/experimental"

module VagrantPlugins
  module HyperV
    module Cap
      module ConfigureDisks
        LOGGER = Log4r::Logger.new("vagrant::plugins::hyperv::configure_disks")

        # The max amount of disks that can be attached to a single device in a controller
        # TODO: Figure out if there's a limit for Hyper-V guests
        MAX_DISK_NUMBER = 30.freeze

        # @param [Vagrant::Machine] machine
        # @param [VagrantPlugins::Kernel_V2::VagrantConfigDisk] defined_disks
        # @return [Hash] configured_disks - A hash of all the current configured disks
        def self.configure_disks(machine, defined_disks)
          return {} if defined_disks.empty?

          return {} if !Vagrant::Util::Experimental.feature_enabled?("disks")

          if defined_disks.size > MAX_DISK_NUMBER
            # you can only attach up to 30 disks per controller, INCLUDING the primary disk
            raise Vagrant::Errors::VirtualBoxDisksDefinedExceedLimit
          end

          machine.ui.info(I18n.t("vagrant.cap.configure_disks.start"))

          current_disks = machine.provider.driver.list_hdds

          configured_disks = {disk: [], floppy: [], dvd: []}

          defined_disks.each do |disk|
            if disk.type == :disk
              disk_data = handle_configure_disk(machine, disk, current_disks)
              configured_disks[:disk] << disk_data unless disk_data.empty?
            elsif disk.type == :floppy
              # TODO: Write me
              machine.ui.info(I18n.t("vagrant.cap.configure_disks.floppy_not_supported", name: disk.name))
            elsif disk.type == :dvd
              # TODO: Write me
              machine.ui.info(I18n.t("vagrant.cap.configure_disks.dvd_not_supported", name: disk.name))
            end
          end

          configured_disks
        end

        protected

        # @param [Vagrant::Machine] machine - the current machine
        # @param [Config::Disk] disk - the current disk to configure
        # @param [Array] all_disks - A list of all currently defined disks in VirtualBox
        # @return [Hash] current_disk - Returns the current disk. Returns nil if it doesn't exist
        def self.get_current_disk(machine, disk, all_disks)
          current_disk = nil
          if disk.primary
            # Ensure we grab the proper primary disk
            # We can't rely on the order of `all_disks`, as they will not
            # always come in port order, but primary is always Port 0 Device 0.
            vm_info = machine.provider.driver.show_vm_info
            primary_uuid = vm_info["SATA Controller-ImageUUID-0-0"]

            current_disk = all_disks.select { |d| d["UUID"] == primary_uuid }.first
          else
            current_disk = all_disks.select { |d| d["Disk Name"] == disk.name}.first
          end

          current_disk
        end

        # Handles all disk configs of type `:disk`
        #
        # @param [Vagrant::Machine] machine - the current machine
        # @param [Config::Disk] disk - the current disk to configure
        # @param [Array] all_disks - A list of all currently defined disks in VirtualBox
        # @return [Hash] - disk_metadata
        def self.handle_configure_disk(machine, disk, all_disks)
          disk_metadata = {}

          # Grab the existing configured disk, if it exists
          current_disk = get_current_disk(machine, disk, all_disks)

          # Configure current disk
          if !current_disk
            # create new disk and attach
            disk_metadata = create_disk(machine, disk)
          elsif compare_disk_size(machine, disk, current_disk)
            disk_metadata = resize_disk(machine, disk, current_disk)
          else
            # TODO: What if it needs to be resized?

            disk_info = machine.provider.driver.get_port_and_device(current_disk["UUID"])
            if disk_info.empty?
              LOGGER.warn("Disk '#{disk.name}' is not connected to guest '#{machine.name}', Vagrant will attempt to connect disk to guest")
              dsk_info = get_next_port(machine)
              machine.provider.driver.attach_disk(dsk_info[:port],
                                                  dsk_info[:device],
                                                  current_disk["Location"])
            else
              LOGGER.info("No further configuration required for disk '#{disk.name}'")
            end

            disk_metadata = {uuid: current_disk["UUID"], name: disk.name}
          end

          disk_metadata
        end

        # Check to see if current disk is configured based on defined_disks
        #
        # @param [Kernel_V2::VagrantConfigDisk] disk_config
        # @param [Hash] defined_disk
        # @return [Boolean]
        def self.compare_disk_size(machine, disk_config, defined_disk)
          requested_disk_size = Vagrant::Util::Numeric.bytes_to_megabytes(disk_config.size)
          defined_disk_size = defined_disk["Capacity"].split(" ").first.to_f

          if defined_disk_size > requested_disk_size
            machine.ui.warn(I18n.t("vagrant.cap.configure_disks.shrink_size_not_supported", name: disk_config.name))
            return false
          elsif defined_disk_size < requested_disk_size
            return true
          else
            return false
          end
        end

        # Creates and attaches a disk to a machine
        #
        # @param [Vagrant::Machine] machine
        # @param [Kernel_V2::VagrantConfigDisk] disk_config
        def self.create_disk(machine, disk_config)
          machine.ui.detail(I18n.t("vagrant.cap.configure_disks.create_disk", name: disk_config.name))
          # NOTE: At the moment, there are no provider specific configs for Hyper-V
          # but we grab it anyway for future use.
          disk_provider_config = disk_config.provider_config[:hyperv] if disk_config.provider_config

          # TODO: Create and store disk before attaching, if required

          guest_info = machine.provider.driver.show_vm_info
          guest_folder = File.dirname(guest_info["CfgFile"])

          disk_ext = disk_config.disk_ext
          disk_file = File.join(guest_folder, disk_config.name) + ".#{disk_ext}"

          LOGGER.info("Attempting to create a new disk file '#{disk_file}' of size '#{disk_config.size}' bytes")

          disk_var = machine.provider.driver.create_disk(disk_file, disk_config.size, disk_ext.upcase)
          disk_metadata = {uuid: disk_var.split(':').last.strip, name: disk_config.name}

          dsk_controller_info = get_next_port(machine)
          machine.provider.driver.attach_disk(dsk_controller_info[:port], dsk_controller_info[:device], disk_file)

          disk_metadata
        end

        # @param [Vagrant::Machine] machine
        # @param [Config::Disk] disk_config - the current disk to configure
        # @param [Hash] defined_disk - current disk as represented by VirtualBox
        # @return [Hash] - disk_metadata
        def self.resize_disk(machine, disk_config, defined_disk)
          machine.ui.detail(I18n.t("vagrant.cap.configure_disks.resize_disk", name: disk_config.name), prefix: true)

          # TODO: Resize the disks
          machine.provider.driver.resize_disk(defined_disk["Location"], disk_config.size.to_i)

          # Store updated metadata
          disk_metadata = {uuid: defined_disk["UUID"], name: disk_config.name}

          disk_metadata
        end
      end
    end
  end
end
