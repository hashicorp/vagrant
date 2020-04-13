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
          # TODO: Iterate over each disk_meta disk, check if it's still defined in the
          # guests config, and if it's no longer there, remove it from the guest
          disk_meta.each do |d|
            # find d in defined_disk
            # if found, continue on
            # else, remove the disk

            # look at Path instead of Name or UUID
            disk_name  = File.basename(d["path"], '.*')
            dsk = defined_disks.select { |dk| dk.name == disk_name }
            primary_disk_uuid = ""
            ## todo: finish this
            if !dsk.empty? || d["uuid"] == primary_disk_uuid
              next
            else
              #remove disk from guest, and remove from system
            end
          end
        end
      end
    end
  end
end
