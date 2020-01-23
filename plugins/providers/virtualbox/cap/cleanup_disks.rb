require "log4r"
require "vagrant/util/experimental"

module VagrantPlugins
  module ProviderVirtualBox
    module Cap
      module CleanupDisks
        LOGGER = Log4r::Logger.new("vagrant::plugins::virtualbox::cleanup_disks")

        # @param [Vagrant::Machine] machine
        # @param [VagrantPlugins::Kernel_V2::VagrantConfigDisk] defined_disks
        # @param [Hash] disk_meta_file - A hash of all the previously defined disks from the last configure_disk action
        def self.cleanup_disks(machine, defined_disks, disk_meta_file)
          return if disk_meta_file.values.flatten.empty?

          return if !Vagrant::Util::Experimental.feature_enabled?("virtualbox_disk_hdd")

          handle_cleanup_disk(machine, defined_disks, disk_meta_file["disk"])
          # TODO: Floppy and DVD disks
        end

        protected

        # TODO: This method is duplicated in configure_disks
        #
        # @param [Hash] vm_info - A guests information from vboxmanage
        # @param [String] disk_uuid - the UUID for the disk we are searching for
        # @return [Hash] disk_info - Contains a device and port number
        def self.get_port_and_device(vm_info, disk_uuid)
          disk = {}
          disk_info_key = vm_info.key(disk_uuid)
          return disk if !disk_info_key

          disk_info = disk_info_key.split("-")

          disk[:port] = disk_info[2]
          disk[:device] = disk_info[3]

          return disk
        end

        # @param [Vagrant::Machine] machine
        # @param [VagrantPlugins::Kernel_V2::VagrantConfigDisk] defined_disks
        # @param [Hash] disk_meta - A hash of all the previously defined disks from the last configure_disk action
        def self.handle_cleanup_disk(machine, defined_disks, disk_meta)
          vm_info = machine.provider.driver.show_vm_info

          disk_meta.each do |d|
            dsk = defined_disks.select { |dk| dk.name == d["name"] }
            if !dsk.empty?
              next
            else
              LOGGER.warn("Found disk not in Vagrantfile config: '#{d["name"]}'. Removing disk from guest #{machine.name}")
              disk_info = get_port_and_device(vm_info, d["uuid"])

              machine.ui.warn("Disk '#{d["name"]}' no longer exists in Vagrant config. Removing and closing medium from guest...", prefix: true)

              if disk_info.empty?
                LOGGER.warn("Disk '#{d["name"]}' not attached to guest, but still exists.")
              else
                machine.provider.driver.remove_disk(disk_info[:port], disk_info[:device])
              end

              machine.provider.driver.close_medium(d["uuid"])
            end
          end
        end
      end
    end
  end
end
