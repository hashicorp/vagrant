require "vagrant/util/numeric"

module VagrantPlugins
  module ProviderVirtualBox
    module Cap
      module ConfigureDisks
        # @param [Vagrant::Machine] machine
        # @param [VagrantPlugins::Kernel_V2::VagrantConfigDisk] defined_disks
        def self.configure_disks(machine, defined_disks)
          return nil if defined_disks.empty?
        end

        protected

        # Maybe move these into the virtualbox driver??
        # Versioning might be an issue :shrug:

        def current_vm_disks(driver)
        end

        def vmdk_to_vdi(driver)
        end

        def vdi_to_vmdk(driver)
        end
      end
    end
  end
end
