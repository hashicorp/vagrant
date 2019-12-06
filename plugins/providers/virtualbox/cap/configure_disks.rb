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
      end
    end
  end
end
