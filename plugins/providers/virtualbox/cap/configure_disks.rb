require "log4r"
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
          return if defined_disks.empty?

          return if !Vagrant::Util::Experimental.feature_enabled?("virtualbox_disk_hdd")

          machine.ui.info("Configuring storage mediums...")

          current_disks = machine.provider.driver.list_hdds

          configured_disks = {disk: [], floppy: [], dvd: []}

          defined_disks.each do |disk|
            if disk.type == :disk
              disk_data = handle_configure_disk(machine, disk, current_disks)
              configured_disks[:disk] << disk_data unless disk_data.empty?
            elsif disk.type == :floppy
              # TODO: Write me
              machine.ui.warn("Floppy disk configuration not yet supported. Skipping disk #{disk.name}...")
            elsif disk.type == :dvd
              # TODO: Write me
              machine.ui.warn("DVD disk configuration not yet supported. Skipping disk #{disk.name}...")
            end
          end

          return configured_disks
        end

        protected

        # Handles all disk configs of type `:disk`
        # @param [Hash] - disk_metadata
        def self.handle_configure_disk(machine, disk, all_disks)
          disk_metadata = {}
          # Grab the existing configured disk, if it exists
          current_disk = nil
          if disk.primary
            # TODO: This instead might need to be determined through the show_vm_info data instead
            current_disk = all_disks.first
          else
            current_disk = all_disks.select { |d| d["Disk Name"] == disk.name}.first
          end

          if !current_disk
            # create new disk and attach
            disk_metadata = create_disk(machine, disk)
          elsif compare_disk_state(machine, disk, current_disk)
            disk_metadata = resize_disk(machine, disk, current_disk)
          else
            LOGGER.info("No further configuration required for disk '#{disk.name}'")
            disk_metadata = {uuid: current_disk["UUID"], name: disk.name}
          end

          return disk_metadata
        end

        # Check to see if current disk is configured based on defined_disks
        #
        # @param [Kernel_V2::VagrantConfigDisk] disk_config
        # @param [Hash] defined_disk
        # @return [Boolean]
        def self.compare_disk_state(machine, disk_config, defined_disk)
          requested_disk_size = Vagrant::Util::Numeric.bytes_to_megabytes(disk_config.size)
          defined_disk_size = defined_disk["Capacity"].split(" ").first.to_f

          if defined_disk_size > requested_disk_size
            machine.ui.warn("VirtualBox does not support shrinking disk size. Cannot shrink '#{disk_config.name}' disks size")
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
          machine.ui.detail("Disk '#{disk_config.name}' not found in guest. Creating and attaching disk to guest...")
          guest_info = machine.provider.driver.show_vm_info
          disk_provider_config = disk_config.provider_config[:virtualbox] if disk_config.provider_config

          guest_folder = File.dirname(guest_info["CfgFile"])
          disk_ext = "vdi"

          if disk_provider_config
            if disk_provider_config.include?(:disk_type)
              disk_ext = disk_provider_config[:disk_type].downcase
            end
          end
          disk_file = File.join(guest_folder, disk_config.name) + ".#{disk_ext}"

          # TODO: Round disk_config.size to the nearest 512 bytes to make it divisble by 512
          # Source: https://www.virtualbox.org/ticket/5582
          #
          # note: this might not be required... :thinking: needs more testing
          LOGGER.info("Attempting to create a new disk file '#{disk_file}' of size '#{disk_config.size}' bytes")

          disk_var = machine.provider.driver.create_disk(disk_file, disk_config.size, disk_ext.upcase)
          disk_metadata = {uuid: disk_var.split(':').last.strip, name: disk_config.name}

          # TODO: Determine what port and device to attach disk to???
          # look at guest_info and see what is in use
          # need to get the _correct_ port and device to attach disk to
          # Port is easy (pick the "next one" available), but what about device??? can you have more than one device per controller?
          port = get_next_port(machine)
          device = "0" # TODO: Fix me
          machine.provider.driver.attach_disk(port, device, disk_file)

          disk_metadata
        end

        # TODO: Possibly consolidate this method and just use `get_port_and_device`,
        # and determine which port and device to use from that info instead
        #
        # @param [Vagrant::Machine] machine
        # @return [String] port - The next available port on a given device
        def self.get_next_port(machine)
          vm_info = machine.provider.driver.show_vm_info

          port = 0
          vm_info.each do |key,value|
            if key.include?("ImageUUID")
              disk_info = key.split("-")
              port = disk_info[2]
            else
              next
            end
          end

          port = (port.to_i + 1).to_s
          port
        end

        # @param [Hash] vm_info - Guest info from show_vm_info
        # @param [Hash] defined_disk - A specific disk with info from list_hdd
        # @return [Hash] disk - A hash with `port` and `device` keys found from a matching UUID in vm_info
        def self.get_port_and_device(vm_info, defined_disk)
          disk = {}
          vm_info.each do |key,value|
            if key.include?("ImageUUID") && value == defined_disk["UUID"]
              disk_info = key.split("-")
              disk[:port] = disk_info[2]
              disk[:device] = disk_info[3]
              break
            else
              next
            end
          end

          disk
        end

        def self.resize_disk(machine, disk_config, defined_disk)
          machine.ui.detail("Disk '#{disk_config.name}' needs to be resized. Resizing disk...", prefix: true)

          if defined_disk["Storage format"] == "VMDK"
            LOGGER.warn("Disk type VMDK cannot be resized in VirtualBox. Vagrant will convert disk to VDI format to resize first, and then convert resized disk back to VMDK format")
            # grab disks port and device number
            vm_info = machine.provider.driver.show_vm_info
            disk_info = get_port_and_device(vm_info, defined_disk)
            # clone disk to vdi formatted disk
            vdi_disk_file = vmdk_to_vdi(machine.provider.driver, defined_disk["Location"])
            # resize vdi
            machine.provider.driver.resize_disk(vdi_disk_file, disk_config.size.to_i)

            # remove and close original volume
            machine.provider.driver.remove_disk(disk_info[:port], disk_info[:device])
            machine.provider.driver.close_medium(defined_disk["UUID"])

            vmdk_disk_file = vdi_to_vmdk(machine.provider.driver, vdi_disk_file)
            machine.provider.driver.attach_disk(disk_info[:port], disk_info[:device], vmdk_disk_file, "hdd")

            # close cloned volume format
            machine.provider.driver.close_medium(vdi_disk_file)

            # Get new disk UUID for vagrant disk_meta file
            new_disk_info = machine.provider.driver.list_hdds.select { |h| h["Location"] == defined_disk["Location"] }.first
            defined_disk = new_disk_info

            # TODO: If any of the above steps fail, display a useful error message
            # telling the user how to recover
            #
            # Vagrant could also have a "rescue" here where in the case of failure, it simply
            # reattaches the original disk
          else
            machine.provider.driver.resize_disk(defined_disk["Location"], disk_config.size.to_i)
          end

          disk_metadata = {uuid: defined_disk["UUID"], name: disk_config.name}
          return disk_metadata
        end

        # @param [VagrantPlugins::VirtualboxProvider::Driver] driver
        # @param [String] defined_disk_path
        # @return [String] destination - The cloned disk
        def self.vmdk_to_vdi(driver, defined_disk_path)
          LOGGER.warn("Converting disk '#{defined_disk_path}' from 'vmdk' to 'vdi' format")
          source = defined_disk_path
          destination = File.join(File.dirname(source), File.basename(source, ".*")) + ".vdi"

          driver.clone_disk(source, destination, 'VDI')

          destination
        end

        # @param [VagrantPlugins::VirtualboxProvider::Driver] driver
        # @param [String] defined_disk_path
        # @return [String] destination - The cloned disk
        def self.vdi_to_vmdk(driver, defined_disk_path)
          LOGGER.warn("Converting disk '#{defined_disk_path}' from 'vdi' to 'vmdk' format")
          source = defined_disk_path
          destination = File.join(File.dirname(source), File.basename(source, ".*")) + ".vmdk"

          driver.clone_disk(source, destination, 'VMDK')

          destination
        end
      end
    end
  end
end
