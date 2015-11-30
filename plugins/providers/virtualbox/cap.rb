module VagrantPlugins
  module ProviderVirtualBox
    module Cap
      # Reads the forwarded ports that currently exist on the machine
      # itself. This raises an exception if the machine isn't running.
      #
      # This also may not match up with configured forwarded ports, because
      # Vagrant auto port collision fixing may have taken place.
      #
      # @return [Hash<Integer, Integer>] Host => Guest port mappings.
      def self.forwarded_ports(machine)
        return nil if machine.state.id != :running

        {}.tap do |result|
          machine.provider.driver.read_forwarded_ports.each do |_, _, h, g|
            result[h] = g
          end
        end
      end

      # Reads the network interface card MAC addresses and returns them.
      #
      # @return [Hash<String, String>] Adapter => MAC address
      def self.nic_mac_addresses(machine)
        machine.provider.driver.read_mac_addresses
      end

      # Returns a list of the snapshots that are taken on this machine.
      #
      # @return [Array<String>] Snapshot Name
      def self.snapshot_list(machine)
        machine.provider.driver.list_snapshots(machine.id)
      end
    end
  end
end
