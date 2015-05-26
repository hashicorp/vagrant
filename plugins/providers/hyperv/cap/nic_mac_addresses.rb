module VagrantPlugins
  module HyperV
    module Cap
      module NicMacAddresses
        def self.nic_mac_addresses(machine)
          machine.provider.driver.read_mac_addresses
        end
      end
    end
  end
end
