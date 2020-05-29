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
          controller = machine.provider.driver.storage_controllers.detect { |c| c.sata_controller? }
          primary_disk = controller.attachments.detect { |a| a[:port] == "0" && a[:device] == "0" }[:uuid]

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
                  # TODO: write test for sata controller with another name
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
          controller = machine.provider.driver.storage_controllers.detect { |c| c.ide_controller? }

          unless dvd_meta.nil?
            dvd_meta.each do |d|
              dsk = defined_dvds.select { |dk| dk.name == d["name"] }
              if !dsk.empty?
                next
              else
                LOGGER.warn("Found dvd not in Vagrantfile config: '#{d["name"]}'. Removing dvd from guest #{machine.name}")
                attachments = controller.attachments.select { |a| a[:uuid] == d["uuid"] }
                attachments.each do |attachment|
                  machine.ui.warn("DVD '#{d["name"]}' no longer exists in Vagrant config. Removing medium from guest...", prefix: true)
                  machine.provider.driver.remove_disk(attachment[:port].to_s, attachment[:device].to_s, controller.name)
                end
              end
            end
          end
        end
      end
    end
  end
end
