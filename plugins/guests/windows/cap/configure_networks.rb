require "log4r"

require_relative '../../communication/guestnetwork'
require_relative '../../communication/winrmshell'
require_relative '../../errors'
require_relative '../../helper'
require_relative '../../windows_machine'

module VagrantPlugins
  module GuestWindows
    module Cap
      module ConfigureNetworks
        @@logger = Log4r::Logger.new("vagrant::guest::windows::configure_networks")

        def self.configure_networks(machine, networks)
          @@logger.debug("Networks: #{networks.inspect}")

          windows_machine = VagrantWindows::WindowsMachine.new(machine)
          guest_network = VagrantWindows::Communication::GuestNetwork.new(windows_machine.winrmshell)
          if windows_machine.is_vmware?()
            @@logger.warn('Configuring secondary network adapters through VMware is not yet supported.')
            @@logger.warn('You will need to manually configure the network adapter.')
          else
            vm_interface_map = create_vm_interface_map(windows_machine, guest_network)
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
                raise WindowsError, "#{network_type} network type is not supported, try static or dhcp"
              end
            end
          end
          guest_network.set_all_networks_to_work() if windows_machine.windows_config.set_work_network
        end

        #{1=>{:name=>"Local Area Connection", :mac_address=>"0800275FAC5B", :interface_index=>"11", :index=>"7"}}
        def self.create_vm_interface_map(windows_machine, guest_network)
          vm_interface_map = {}
          driver_mac_address = windows_machine.read_mac_addresses.invert
          @@logger.debug("mac addresses: #{driver_mac_address.inspect}")
          guest_network.network_adapters().each do |nic|
            @@logger.debug("nic: #{nic.inspect}")
            naked_mac = nic[:mac_address].gsub(':','')
            if driver_mac_address[naked_mac]
              vm_interface_map[driver_mac_address[naked_mac]] = {
                :net_connection_id => nic[:net_connection_id],
                :mac_address => naked_mac,
                :interface_index => nic[:interface_index],
                :index => nic[:index] }
            end
          end
          @@logger.debug("vm_interface_map: #{vm_interface_map.inspect}")
          vm_interface_map
        end
      end
    end
  end
end
