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
            current_disk = all_disks.first
          else
            current_disk = all_disks.select { |d| d["Disk Name"] == disk.name}.first
          end

          if !current_disk
            machine.ui.warn("Disk '#{disk.name}' not found in guest. Creating and attaching disk to guest...")
            # create new disk and attach
            create_disk(machine, disk)
          elsif !compare_disk_state(disk, current_disk)
            machine.ui.warn("Disk '#{disk.name}' needs to be resized. Attempting to resize disk...", prefix: true)
            resize_disk(machine, disk, current_disk)
          else
            # log no need to reconfigure disk, already in desired state
            LOGGER.info("No further configuration required for disk '#{disk.name}'.")
          end
        end

        # Check to see if current disk is configured based on defined_disks
        #
        # @param [Kernel_V2::VagrantConfigDisk] disk_config
        # @param [Hash] defined_disk
        # @return [Boolean]
        def self.compare_disk_state(disk_config, defined_disk)
          requested_disk_size = Vagrant::Util::Numeric.bytes_to_megabytes(disk_config.size)
          defined_disk_size = defined_disk["Capacity"].split(" ").first.to_f

          return defined_disk_size == requested_disk_size
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
          disk_file = "#{guest_folder}/#{disk_config.name}.#{disk_ext}"
          require 'pry'
          binding.pry

          # TODO: Round disk_config.size to the nearest 512 bytes to make it divisble by 512
          # Source: https://www.virtualbox.org/ticket/5582
          LOGGER.info("Attempting to create a new disk file '#{disk_file}' of size '#{disk_config.size}' bytes")
          machine.provider.driver.create_disk(disk_file, disk_config.size, disk_ext.upcase)

          # TODO: Determine what port and device to attach disk to???
          # look at guest_info and see what is in use
          #machine.provider.driver.attach_disk(machine.id, nil, nil, disk_file)
        end

        def self.resize_disk(machine, disk_config, defined_disk)
          # check if vmdk (probably)
          # if so, convert
          # then resize
          # if converted, convert back
          # reattach??
          # done
        end

        def self.vmdk_to_vdi(driver)
          LOGGER.warn("Converting disk from vmdk to vdi format")
        end

        def self.vdi_to_vmdk(driver)
          LOGGER.warn("Converting disk from vdi to vmdk format")
        end
      end
    end
  end
end
