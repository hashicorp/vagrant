module VagrantPlugins
  module ProviderVirtualBox
    module Cap
      module ConfigureDisks
        def self.configure_disks(machine, defined_disks)
          return nil if defined_disks.empty?
        end
      end
    end
  end
end
