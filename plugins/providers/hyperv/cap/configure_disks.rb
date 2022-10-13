require "log4r"
require "fileutils"
require "vagrant/util/numeric"
require "vagrant/util/experimental"

module VagrantPlugins
  module HyperV
    module Cap
      module ConfigureDisks
        LOGGER = Log4r::Logger.new("vagrant::plugins::hyperv::configure_disks")

        # @param [Vagrant::Machine] machine
        # @param [VagrantPlugins::Kernel_V2::VagrantConfigDisk] defined_disks
        # @return [Hash] configured_disks - A hash of all the current configured disks
        def self.configure_disks(machine, defined_disks)
          return {} if defined_disks.empty?

          return {} if !Vagrant::Util::Experimental.feature_enabled?("disks")

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
            # always come in port order, but primary should always be Location 0 Number 0.

            current_disk = all_disks.detect { |d| d["ControllerLocation"] == 0 && d["ControllerNumber"] == 0 }

            # Need to get actual disk info to obtain UUID instead of what's returned
            #
            # This is not required for newly created disks, as its metadata is
            # set when creating and attaching the disk. This is only for the primary
            # disk, since it already exists.
            current_disk = machine.provider.driver.get_disk(current_disk["Path"])
          else
            # Hyper-V disk names aren't the actual names of the disk, so we have
            # to grab the name from the file path instead
            current_disk = all_disks.detect { |d| File.basename(d["Path"], '.*') == disk.name}
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
            disk_metadata = {UUID: current_disk["DiskIdentifier"], Name: disk.name, Path: current_disk["Path"]}
            if disk.primary
              disk_metadata[:primary] = true
            end
          end

          disk_metadata
        end

        # Check to see if current disk is configured based on defined_disks
        #
        # @param [Kernel_V2::VagrantConfigDisk] disk_config
        # @param [Hash] defined_disk
        # @return [Boolean]
        def self.compare_disk_size(machine, disk_config, defined_disk)
          # Hyper-V returns disk size in bytes
          requested_disk_size = disk_config.size
          disk_actual = machine.provider.driver.get_disk(defined_disk["Path"])
          defined_disk_size = disk_actual["Size"]

          if defined_disk_size > requested_disk_size
            if File.extname(disk_actual["Path"]) == ".vhdx"
              # VHDX formats can be shrunk
              return true
            else
              machine.ui.warn(I18n.t("vagrant.cap.configure_disks.shrink_size_not_supported", name: disk_config.name))
              return false
            end
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
          disk_provider_config = {}

          if disk_config.provider_config && disk_config.provider_config.key?(:hyperv)
            disk_provider_config = disk_config.provider_config[:hyperv]
          end

          if !disk_provider_config.empty?
            disk_provider_config = convert_size_vars!(disk_provider_config)
          end

          # Get the machines data dir, that will now be the path for the new disk
          guest_disk_folder = machine.data_dir.join("Virtual Hard Disks")

          if disk_config.file
            disk_file = disk_config.file
            LOGGER.info("Disk already defined by user at '#{disk_file}'. Using this disk instead of creating a new one...")
          else
            # Set the extension
            disk_ext = disk_config.disk_ext
            disk_file = File.join(guest_disk_folder, disk_config.name) + ".#{disk_ext}"

            LOGGER.info("Attempting to create a new disk file '#{disk_file}' of size '#{disk_config.size}' bytes")

            machine.provider.driver.create_disk(disk_file, disk_config.size, disk_provider_config)
          end

          disk_info = machine.provider.driver.get_disk(disk_file)
          disk_metadata = {UUID: disk_info["DiskIdentifier"], Name: disk_config.name, Path: disk_info["Path"]}

          machine.provider.driver.attach_disk(disk_file, disk_provider_config)

          disk_metadata
        end

        # Converts any "shortcut" options such as "123MB" into its byte form. This
        # is due to what parameter type is expected when calling the `New-VHD`
        # powershell command
        #
        # @param [Hash] disk_provider_config
        # @return [Hash] disk_provider_config
        def self.convert_size_vars!(disk_provider_config)
          if disk_provider_config.key?(:BlockSizeBytes)
            bytes = Vagrant::Util::Numeric.string_to_bytes(disk_provider_config[:BlockSizeBytes])
            disk_provider_config[:BlockSizeBytes] = bytes
          end

          disk_provider_config
        end

        # @param [Vagrant::Machine] machine
        # @param [Config::Disk] disk_config - the current disk to configure
        # @param [Hash] defined_disk - current disk as represented by VirtualBox
        # @return [Hash] - disk_metadata
        def self.resize_disk(machine, disk_config, defined_disk)
          machine.ui.detail(I18n.t("vagrant.cap.configure_disks.resize_disk", name: disk_config.name), prefix: true)

          machine.provider.driver.resize_disk(defined_disk["Path"], disk_config.size.to_i)

          disk_info = machine.provider.driver.get_disk(defined_disk["Path"])

          # Store updated metadata
          disk_metadata = {UUID: disk_info["DiskIdentifier"], Name: disk_config.name, Path: disk_info["Path"]}

          disk_metadata
        end
      end
    end
  end
end
