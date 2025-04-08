# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

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

          handle_cleanup_disk(machine, defined_disks, disk_meta_file["disk"])
          handle_cleanup_dvd(machine, defined_disks, disk_meta_file["dvd"])
          # TODO: Floppy disks
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

        def self.handle_cleanup_dvd(machine, defined_disks, disk_meta)
          # Get a list of all attached DVD drives
          attached = machine.provider.driver.read_scsi_controllers.map do |controller|
            controller["Drives"].map do |drive|
              drive if drive["DvdMediaType"].to_i == 1
            end.compact
          end.flatten.compact

          # Generate list of dvd disks that previously
          # existed but are no longer defined
          orphan_attachments = disk_meta.find_all do |mdisk|
            defined_disks.none? do |defined_disk|
              defined_disk.type == :dvd &&
                File.expand_path(mdisk["Path"]) == File.expand_path(defined_disk.file)
            end
          end

          # Remove any entries that are not currently
          # attached
          orphan_attachments.delete_if do |mdisk|
            attached.any? do |attachment|
              File.expand_path(attachment["Path"]) == mdisk["Path"]
            end
          end

          # Now remove any orphan attachments that remain
          orphan_attachments.each do |mdisk|
            LOGGER.debug("removing dvd attachment: #{mdisk}")

            machine.provider.driver.detach_dvd(
              mdisk["ControllerLocation"],
              mdisk["ControllerNumber"]
            )
          end
        end
      end
    end
  end
end
