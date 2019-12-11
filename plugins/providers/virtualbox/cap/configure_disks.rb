require "vagrant/util/numeric"

module VagrantPlugins
  module ProviderVirtualBox
    module Cap
      module ConfigureDisks
        # @param [Vagrant::Machine] machine
        # @param [VagrantPlugins::Kernel_V2::VagrantConfigDisk] defined_disks
        def self.configure_disks(machine, defined_disks)
          return if defined_disks.empty?

          current_disks = machine.provider.driver.list_hdds
          # Compare current disks to config, and if there's a delta, adjust accordingly
          #
          # Compare by name if possible
          defined_disks.each do |disk|
            if disk.type == :disk
            end
          end
        end

        protected

        def self.vmdk_to_vdi(driver)
        end

        def self.vdi_to_vmdk(driver)
        end
      end
    end
  end
end
