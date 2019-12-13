require "log4r"
require "vagrant/util/numeric"

module VagrantPlugins
  module ProviderVirtualBox
    module Cap
      module ConfigureDisks
        LOGGER = Log4r::Logger.new("vagrant::plugins::virtualbox::configure_disks")

        # @param [Vagrant::Machine] machine
        # @param [VagrantPlugins::Kernel_V2::VagrantConfigDisk] defined_disks
        def self.configure_disks(machine, defined_disks)
          return if defined_disks.empty?

          machine.ui.info("Configuring storage mediums...")

          current_disks = machine.provider.driver.list_hdds

          defined_disks.each do |disk|
            if disk.type == :disk
              handle_configure_disk(machine, disk, current_disks)
            elsif disk.type == :floppy
              # TODO: Write me
            elsif disk.type == :dvd
              # TODO: Write me
            end
          end
        end

        protected

        # Handles all disk configs of type `:disk`
        def self.handle_configure_disk(machine, disk, all_disks)
          # Grab the existing configured disk, if it exists
          current_disk = nil
          if disk.primary
            # TODO: This instead might need to be determined through the show_vm_info data instead
            current_disk = all_disks.first
          else
            current_disk = all_disks.select { |d| d["Disk Name"] == disk.name}.first
          end

          if !current_disk
            machine.ui.detail("Disk '#{disk.name}' not found in guest. Creating and attaching disk to guest...")
            # create new disk and attach
            create_disk(machine, disk)
          elsif compare_disk_state(machine, disk, current_disk)
            machine.ui.detail("Disk '#{disk.name}' needs to be resized. Resizing disk...", prefix: true)
            resize_disk(machine, disk, current_disk)
          else
            # log no need to reconfigure disk, already in desired state
            LOGGER.info("No further configuration required for disk '#{disk.name}'")
          end
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
          guest_info = machine.provider.driver.show_vm_info
          disk_provider_config = disk_config.provider_config[:virtualbox]

          guest_folder = File.dirname(guest_info["CfgFile"])
          disk_ext = "vdi"

          if disk_provider_config
            if disk_provider_config.include?(:disk_type)
              disk_ext = disk_provider_config[:disk_type].downcase
            end
          end
          # TODO: use File class for path separator instead
          #disk_file = "#{guest_folder}/#{disk_config.name}.#{disk_ext}"
          disk_file = File.join(guest_folder, disk_config.name) + ".#{disk_ext}"

          # TODO: Round disk_config.size to the nearest 512 bytes to make it divisble by 512
          # Source: https://www.virtualbox.org/ticket/5582
          LOGGER.info("Attempting to create a new disk file '#{disk_file}' of size '#{disk_config.size}' bytes")
          machine.provider.driver.create_disk(disk_file, disk_config.size, disk_ext.upcase)

          # TODO: Determine what port and device to attach disk to???
          # look at guest_info and see what is in use

          # need to get the _correct_ port and device to attach disk to
          # Port is easy (pick the "next one" available), but what about device??? can you have more than one device per controller?
          port = get_next_port(machine)
          device = "0"
          machine.provider.driver.attach_disk(machine.id, port, device, disk_file)
        end

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
          if defined_disk["Storage format"] == "VMDK"
            LOGGER.warn("Disk type VMDK cannot be resized in VirtualBox. Vagrant will convert disk to VDI format to resize first, and then convert resized disk back to VMDK format")
            # How to:
            # grab disks port and device number
            vm_info = machine.provider.driver.show_vm_info
            disk_info = get_port_and_device(vm_info, defined_disk)
            # clone disk to vdi formatted disk
            vdi_disk_file = vmdk_to_vdi(machine.provider.driver, defined_disk)
            # detatch vmdk disk??
            machine.provider.driver.attach_disk(machine.id, disk_info[:port], disk_info[:device], vdi_disk_file)
            machine.provider.driver.remove_disk(defined_disk["Location"])
            # resize vdi
            machine.provider.driver.resize_disk(vdi_disk_file, disk_config.size.to_i)
            # clone disk to vmdk ....(or don't clone back if requested file type is vdi??)
            # attach vmdk to original port/device
            # delete vdi
            # delete vmdk
            #
            # TODO: IF any of the above steps fail, display a useful error message
            # telling the user how to recover
            #
            # Vagrant could also have a "rescue" here where in the case of failure, it simply
            # reattaches the original disk
          else
            machine.provider.driver.resize_disk(defined_disk["Location"], disk_config.size.to_i)
          end
        end

        def self.vmdk_to_vdi(driver, defined_disk)
          LOGGER.warn("Converting disk '#{defined_disk["Disk Name"]}' from 'vmdk' to 'vdi' format")
          # todo: MEDIUM changes if virtualbox is older than 5. Need a proper check/switch
          # Maybe move this into version_4, then version_5
          # if version 4, medium = "hd"
          medium = "medium"

          source = defined_disk["Location"]
          destination = File.join(File.dirname(source), File.basename(source, ".*")) + ".vdi"
          driver.execute("clone#{medium}", source, destination, '--format', 'VDI')

          destination
        end

        def self.vdi_to_vmdk(driver, defined_disk)
          LOGGER.warn("Converting disk from vdi to vmdk format")
          medium = "medium"

          source = defined_disk["Location"]
          destination = File.join(File.dirname(source), File.basename(source, ".*")) + ".vmdk"
          driver.execute("clone#{medium}", source, destination, '--format', 'VMDK')
        end
      end
    end
  end
end
