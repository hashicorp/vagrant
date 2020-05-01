require "log4r"
require "vagrant/util/experimental"

module VagrantPlugins
  module HyperV
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
          all_disks = machine.provider.driver.list_hdds

          disk_meta.each do |d|
            # look at Path instead of Name or UUID
            disk_name  = File.basename(d["Path"], '.*')
            dsk = defined_disks.select { |dk| dk.name == disk_name }

            if !dsk.empty? || d["primary"] == true
              next
            else
              LOGGER.warn("Found disk not in Vagrantfile config: '#{d["Name"]}'. Removing disk from guest #{machine.name}")

              machine.ui.warn(I18n.t("vagrant.cap.cleanup_disks.disk_cleanup", name: d["Name"]), prefix: true)

              disk_actual = all_disks.select { |a| File.realdirpath(a["Path"]) == File.realdirpath(d["Path"]) }.first
              if !disk_actual
                machine.ui.warn(I18n.t("vagrant.cap.cleanup_disks.disk_not_found", name: d["Name"]), prefix: true)
              else
                machine.provider.driver.remove_disk(disk_actual["ControllerType"], disk_actual["ControllerNumber"], disk_actual["ControllerLocation"], disk_actual["Path"])
              end
            end
          end
        end
      end
    end
  end
end
