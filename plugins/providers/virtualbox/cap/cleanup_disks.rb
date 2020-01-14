require "log4r"
require "vagrant/util/experimental"

module VagrantPlugins
  module ProviderVirtualBox
    module Cap
      module CleanupDisks
        LOGGER = Log4r::Logger.new("vagrant::plugins::virtualbox::cleanup_disks")

        # @param [Vagrant::Machine] machine
        # @param [VagrantPlugins::Kernel_V2::VagrantConfigDisk] defined_disks
        # @param [Hash] disk_meta_file
        def self.cleanup_disks(machine, defined_disks, disk_meta_file)
          return if defined_disks.empty?

          return if !Vagrant::Util::Experimental.feature_enabled?("virtualbox_disk_hdd")

          handle_cleanup_disk(machine, defined_disks, disk_meta_file["disk"])
        end

        protected

        # @param [Hash] vm_info - A guests information from vboxmanage
        # @param [String] disk_uuid - the UUID for the disk we are searching for
        # @return [Hash] disk_info - Contains a device and port number
        def self.get_device_port(vm_info, disk_uuid)
          disk_info = {device: nil, port: nil}

          vm_info.each do |key,value|
            if key.include?("ImageUUID") &&
                value == disk_uuid
              info = key.split("-")
              disk_info[:port] = info[2]
              disk_info[:device] = info[3]
              break
            else
              next
            end
          end

          disk_info
        end

        def self.handle_cleanup_disk(machine, defined_disks, disk_meta)
          vm_info = machine.provider.driver.show_vm_info

          disk_meta.each do |d|
            dsk = defined_disks.select { |dk| dk.name == d["name"] }
            if !dsk.empty?
              next
            else
              LOGGER.warn("Found disk not in Vagrantfile config: '#{d["name"]}'. Removing disk from guest #{machine.name}")
              disk_info = get_device_port(vm_info, d["uuid"])

              machine.ui.detail("Disk '#{d["name"]}' no longer exists in Vagrant config. Removing and closing medium from guest...", prefix: true)

              # TODO: Maybe add a prompt for yes/no for closing the medium
              machine.provider.driver.remove_disk(disk_info[:port], disk_info[:device])
              machine.provider.driver.close_medium(d["uuid"])
            end
          end
        end
      end
    end
  end
end
