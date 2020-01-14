require "log4r"
require "vagrant/util/numeric"
require "vagrant/util/experimental"

module VagrantPlugins
  module ProviderVirtualBox
    module Cap
      module CleanupDisks
        LOGGER = Log4r::Logger.new("vagrant::plugins::virtualbox::cleanup_disks")

        # @param [Vagrant::Machine] machine
        # @param [VagrantPlugins::Kernel_V2::VagrantConfigDisk] defined_disks
        def self.cleanup_disks(machine, defined_disks)
          return if defined_disks.empty?

          return if !Vagrant::Util::Experimental.feature_enabled?("virtualbox_disk_hdd")
        end

        protected
      end
    end
  end
end
