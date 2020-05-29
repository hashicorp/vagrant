require "log4r"
require "fileutils"
require "vagrant/util/numeric"
require "vagrant/util/experimental"

module VagrantPlugins
  module ProviderVirtualBox
    module Cap
      module ConfigureDisks
        LOGGER = Log4r::Logger.new("vagrant::plugins::virtualbox::configure_disks")

        # @param [Vagrant::Machine] machine
        # @param [VagrantPlugins::Kernel_V2::VagrantConfigDisk] defined_disks
        # @return [Hash] configured_disks - A hash of all the current configured disks
        def self.configure_disks(machine, defined_disks)
          return {} if defined_disks.empty?

          return {} if !Vagrant::Util::Experimental.feature_enabled?("disks")

          disks_defined = defined_disks.select { |d| d.type == :disk }
          controller = machine.provider.driver.storage_controllers.detect { |c| c.sata_controller? }
          if disks_defined.any? && controller && disks_defined.size > controller.maxportcount
            raise Vagrant::Errors::VirtualBoxDisksDefinedExceedLimit
          end

          dvds_defined = defined_disks.select { |d| d.type == :dvd }
          controller = machine.provider.driver.storage_controllers.detect { |c| c.ide_controller? }
          if dvds_defined.any? && controller && dvds_defined.size > controller.maxportcount
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
              dvd_data = handle_configure_dvd(machine, disk)
              configured_disks[:dvd] << dvd_data unless dvd_data.empty?
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
            controller = machine.provider.driver.storage_controllers.detect { |c| c.sata_controller? }
            primary = controller.attachments.detect { |a| a[:port] == "0" && a[:device] == "0" }
            primary_uuid = primary[:uuid]

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

        # Handles all disk configs of type `:dvd`
        #
        # @param [Vagrant::Machine] machine - the current machine
        # @param [Config::Disk] dvd - the current disk to configure
        # @return [Hash] - dvd_metadata
        def self.handle_configure_dvd(machine, dvd)
          controller = machine.provider.driver.storage_controllers.detect { |c| c.ide_controller? }

          disk_info = get_next_port(machine, controller.name)
          machine.provider.driver.attach_disk(disk_info[:port], disk_info[:device], dvd.file, "dvddrive")

          # Refresh the controller information
          controller = machine.provider.driver.storage_controllers.detect { |c| c.ide_controller? }
          attachment = controller.attachments.detect { |a| a[:port] == disk_info[:port] &&
                                                           a[:device] == disk_info[:device] }

          if attachment
            {uuid: attachment[:uuid], name: dvd.name}
          else
            {}
          end
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
          # NOTE: At the moment, there are no provider specific configs for VirtualBox
          # but we grab it anyway for future use.
          disk_provider_config = disk_config.provider_config[:virtualbox] if disk_config.provider_config

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

        # Finds the next available port
        #
        # SATA Controller-ImageUUID-0-0 (sub out ImageUUID)
        # - Controller: SATA Controller
        # - Port: 0
        # - Device: 0
        #
        # Note: Virtualbox returns the string above with the port and device info
        #  disk_info = key.split("-")
        #  port = disk_info[2]
        #  device = disk_info[3]
        #
        # @param [Vagrant::Machine] machine
        # @param [String] controller name (defaults to "SATA Controller")
        # @return [Hash] dsk_info - The next available port and device on a given controller
        def self.get_next_port(machine, controller_name="SATA Controller")
          controller = machine.provider.driver.storage_controllers.detect { |c| c.name == controller_name }
          # TODO: definitely need an error for this
          dsk_info = {}

          if controller.sata_controller?
            used_ports = controller.attachments.map { |a| a[:port].to_i }
            next_available_port = ((0..(controller.maxportcount-1)).to_a - used_ports).first

            dsk_info[:port] = next_available_port.to_s
            dsk_info[:device] = "0"
          else
            # IDE Controllers have primary/secondary devices, so find the first port
            # with an empty device
            (0..(controller.maxportcount-1)).each do |port|
              # Skip this port if it's full
              port_attachments = controller.attachments.select { |a| a[:port] == port.to_s }
              next if port_attachments.count == 2

              dsk_info[:port] = port.to_s

              # Check for a free device
              if port_attachments.detect { |a| a[:device] == "0" }
                dsk_info[:device] = "1"
              else
                dsk_info[:device] = "0"
              end
            end
          end

          if dsk_info[:port].to_s.empty?
            # This likely only occurs if additional disks have been added outside of Vagrant configuration
            LOGGER.warn("There are no more available ports to attach disks to for the controller '#{controller}'. Clear up some space on the controller '#{controller}' to attach new disks.")
            raise Vagrant::Errors::VirtualBoxDisksDefinedExceedLimit
          end

          dsk_info
        end

        # @param [Vagrant::Machine] machine
        # @param [Config::Disk] disk_config - the current disk to configure
        # @param [Hash] defined_disk - current disk as represented by VirtualBox
        # @return [Hash] - disk_metadata
        def self.resize_disk(machine, disk_config, defined_disk)
          machine.ui.detail(I18n.t("vagrant.cap.configure_disks.resize_disk", name: disk_config.name), prefix: true)

          if defined_disk["Storage format"] == "VMDK"
            LOGGER.warn("Disk type VMDK cannot be resized in VirtualBox. Vagrant will convert disk to VDI format to resize first, and then convert resized disk back to VMDK format")

            # grab disk to be resized port and device number
            disk_info = machine.provider.driver.get_port_and_device(defined_disk["UUID"])
            # original disk information in case anything goes wrong during clone/resize
            original_disk = defined_disk
            backup_disk_location = "#{original_disk["Location"]}.backup"

            # clone disk to vdi formatted disk
            vdi_disk_file = machine.provider.driver.vmdk_to_vdi(defined_disk["Location"])
            # resize vdi
            machine.provider.driver.resize_disk(vdi_disk_file, disk_config.size.to_i)

            begin
              # Danger Zone

              # remove and close original volume
              machine.provider.driver.remove_disk(disk_info[:port], disk_info[:device])
              # Create a backup of the original disk if something goes wrong
              LOGGER.warn("Making a backup of the original disk at #{defined_disk["Location"]}")
              FileUtils.mv(defined_disk["Location"], backup_disk_location)

              # we have to close here, otherwise we can't re-clone after
              # resizing the vdi disk
              machine.provider.driver.close_medium(defined_disk["UUID"])

              # clone back to original vmdk format and attach resized disk
              vmdk_disk_file = machine.provider.driver.vdi_to_vmdk(vdi_disk_file)
              machine.provider.driver.attach_disk(disk_info[:port], disk_info[:device], vmdk_disk_file, "hdd")
            rescue ScriptError, SignalException, StandardError
              LOGGER.warn("Vagrant encountered an error while trying to resize a disk. Vagrant will now attempt to reattach and preserve the original disk...")
              machine.ui.error(I18n.t("vagrant.cap.configure_disks.recovery_from_resize",
                                      location: original_disk["Location"],
                                      name: machine.name))
              recover_from_resize(machine, disk_info, backup_disk_location, original_disk, vdi_disk_file)

              raise
            ensure
              # Remove backup disk file if all goes well
              FileUtils.remove(backup_disk_location, force: true)
            end

            # Remove cloned resized volume format
            machine.provider.driver.close_medium(vdi_disk_file)

            # Get new updated disk UUID for vagrant disk_meta file
            new_disk_info = machine.provider.driver.list_hdds.select { |h| h["Location"] == defined_disk["Location"] }.first
            defined_disk = new_disk_info
          else
            machine.provider.driver.resize_disk(defined_disk["Location"], disk_config.size.to_i)
          end

          disk_metadata = {uuid: defined_disk["UUID"], name: disk_config.name}

          disk_metadata
        end

        # Recovery method for when an exception occurs during the process of resizing disks
        #
        # It attempts to move back the backup disk into place, and reattach it to the guest before
        # raising the original error
        #
        # @param [Vagrant::Machine] machine
        # @param [Hash] disk_info - The disk device and port number to attach back to
        # @param [String] backup_disk_location - The place on disk where vagrant made a backup of the original disk being resized
        # @param [Hash] original_disk - The disk information from VirtualBox
        # @param [String] vdi_disk_file - The place on disk where vagrant made a clone of the original disk being resized
        def self.recover_from_resize(machine, disk_info, backup_disk_location, original_disk, vdi_disk_file)
          begin
            # move backup to original name
            FileUtils.mv(backup_disk_location, original_disk["Location"], force: true)
            # Attach disk
            machine.provider.driver.
              attach_disk(disk_info[:port], disk_info[:device], original_disk["Location"], "hdd")

            # Remove cloned disk if still hanging around
            if vdi_disk_file
              machine.provider.driver.close_medium(vdi_disk_file)
            end

            # We recovered!
            machine.ui.warn(I18n.t("vagrant.cap.configure_disks.recovery_attached_disks"))
          rescue => e
            LOGGER.error("Vagrant encountered an error while trying to recover. It will now show the original error and continue...")
            LOGGER.error(e)
          end
        end
      end
    end
  end
end
