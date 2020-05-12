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

          return if !Vagrant::Util::Experimental.feature_enabled?("disks")

          handle_cleanup_disk(machine, defined_disks, disk_meta_file["disk"])
          handle_cleanup_dvd(machine, defined_disks, disk_meta_file["dvd"])
          # TODO: Floppy disks
        end

        protected

        # @param [Vagrant::Machine] machine
        # @param [VagrantPlugins::Kernel_V2::VagrantConfigDisk] defined_disks
        # @param [Hash] disk_meta - A hash of all the previously defined disks from the last configure_disk action
        def self.handle_cleanup_disk(machine, defined_disks, disk_meta)
          vm_info = machine.provider.driver.show_vm_info
          primary_disk = vm_info["SATA Controller-ImageUUID-0-0"]

          unless disk_meta.nil?
            disk_meta.each do |d|
              dsk = defined_disks.select { |dk| dk.name == d["name"] }
              if !dsk.empty? || d["uuid"] == primary_disk
                next
              else
                LOGGER.warn("Found disk not in Vagrantfile config: '#{d["name"]}'. Removing disk from guest #{machine.name}")
                disk_info = machine.provider.driver.get_port_and_device(d["uuid"])

                machine.ui.warn(I18n.t("vagrant.cap.cleanup_disks.disk_cleanup", name: d["name"]), prefix: true)

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

        # @param [Vagrant::Machine] machine
        # @param [VagrantPlugins::Kernel_V2::VagrantConfigDisk] defined_dvds
        # @param [Hash] dvd_meta - A hash of all the previously defined dvds from the last configure_disk action
        def self.handle_cleanup_dvd(machine, defined_dvds, dvd_meta)
          controller = "IDE Controller"
          vm_info = machine.provider.driver.show_vm_info

          unless dvd_meta.nil?
            dvd_meta.each do |d|
              dsk = defined_dvds.select { |dk| dk.name == d["name"] }
              if !dsk.empty?
                next
              else
                LOGGER.warn("Found dvd not in Vagrantfile config: '#{d["name"]}'. Removing dvd from guest #{machine.name}")
                (0..1).each do |port|
                  (0..1).each do |device|
                    if d["uuid"] == vm_info["#{controller}-ImageUUID-#{port}-#{device}"]
                      machine.ui.warn("DVD '#{d["name"]}' no longer exists in Vagrant config. Removing medium from guest...", prefix: true)
                      machine.provider.driver.remove_disk(port.to_s, device.to_s, controller)
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
