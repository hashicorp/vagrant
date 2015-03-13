require "log4r"

require_relative "../guest_network"

module VagrantPlugins
  module GuestWindows
    module Cap
      module ConfigureNetworks
        @@logger = Log4r::Logger.new("vagrant::guest::windows::configure_networks")

        def self.configure_networks(machine, networks)
          if machine.config.vm.communicator != :winrm
            raise Errors::NetworkWinRMRequired
          end

          @@logger.debug("Networks: #{networks.inspect}")

          guest_network = GuestNetwork.new(machine.communicate)
          if machine.provider_name.to_s.start_with?("vmware")
            machine.ui.warn("Configuring secondary network adapters through VMware ")
            machine.ui.warn("on Windows is not yet supported. You will need to manually")
            machine.ui.warn("configure the network adapter.")
          else
            vm_interface_map = create_vm_interface_map(machine, guest_network)
            networks.each do |network|
              interface = vm_interface_map[network[:interface]+1]
              if interface.nil?
                @@logger.warn("Could not find interface for network #{network.inspect}")
                next
              end

              network_type = network[:type].to_sym
              if network_type == :static
                guest_network.configure_static_interface(
                  interface[:index],
                  interface[:net_connection_id],
                  network[:ip],
                  network[:netmask])
              elsif network_type == :dhcp
                guest_network.configure_dhcp_interface(
                  interface[:index],
                  interface[:net_connection_id])
              else
                raise "#{network_type} network type is not supported, try static or dhcp"
              end
            end
          end

          if machine.config.windows.set_work_network
            guest_network.set_all_networks_to_work
          end
        end

        def self.create_vm_interface_map(machine, guest_network)
          if !machine.provider.capability?(:nic_mac_addresses)
            raise Errors::CantReadMACAddresses,
              provider: machine.provider_name.to_s
          end

          driver_mac_address = machine.provider.capability(:nic_mac_addresses).invert
          @@logger.debug("mac addresses: #{driver_mac_address.inspect}")

          vm_interface_map = {}
          guest_network.network_adapters.each do |nic|
            @@logger.debug("nic: #{nic.inspect}")
            naked_mac = nic[:mac_address].gsub(':','')
            # If the :net_connection_id entry is nil then it is probably a virtual connection
            # and should be ignored.
            if driver_mac_address[naked_mac] && !nic[:net_connection_id].nil?
              vm_interface_map[driver_mac_address[naked_mac]] = {
                net_connection_id: nic[:net_connection_id],
                mac_address: naked_mac,
                interface_index: nic[:interface_index],
                index: nic[:index] }
            end
          end

          @@logger.debug("vm_interface_map: #{vm_interface_map.inspect}")
          vm_interface_map
        end
      end
    end
  end
end
