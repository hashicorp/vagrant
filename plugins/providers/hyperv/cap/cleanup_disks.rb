require "log4r"
require "vagrant/util/experimental"

module VagrantPlugins
  module Hyperv
    module Cap
      module CleanupDisks
        LOGGER = Log4r::Logger.new("vagrant::plugins::hyperv::cleanup_disks")

        # @param [Vagrant::Machine] machine
        # @param [VagrantPlugins::Kernel_V2::VagrantConfigDisk] defined_disks
        # @param [Hash] disk_meta_file - A hash of all the previously defined disks from the last configure_disk action
        def self.cleanup_disks(machine, defined_disks, disk_meta_file)
          return if disk_meta_file.values.flatten.empty?

          return if !Vagrant::Util::Experimental.feature_enabled?("disks")

          handle_cleanup_disk(machine, defined_disks, disk_meta_file["disk"])
          # TODO: Floppy and DVD disks
        end

        protected

        # @param [Vagrant::Machine] machine
        # @param [VagrantPlugins::Kernel_V2::VagrantConfigDisk] defined_disks
        # @param [Hash] disk_meta - A hash of all the previously defined disks from the last configure_disk action
        def self.handle_cleanup_disk(machine, defined_disks, disk_meta)
          vm_info = machine.provider.driver.show_vm_info
          primary_disk = vm_info["SATA Controller-ImageUUID-0-0"]

          disk_meta.each do |d|
            dsk = defined_disks.select { |dk| dk.name == d["name"] }
            if !dsk.empty? || d["uuid"] == primary_disk
              next
            else
              LOGGER.warn("Found disk not in Vagrantfile config: '#{d["name"]}'. Removing disk from guest #{machine.name}")
              disk_info = machine.provider.driver.get_port_and_device(d["uuid"])

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
