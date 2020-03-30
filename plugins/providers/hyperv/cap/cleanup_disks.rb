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
          # Iterate over each disk_meta disk, check if it's still defined in the
          # guests config, and if it's no longer there, remove it from the guest
        end
      end
    end
  end
end
