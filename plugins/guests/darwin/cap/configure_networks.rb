require "tempfile"

require "vagrant/util/template_renderer"

module VagrantPlugins
  module GuestDarwin
    module Cap
      class ConfigureNetworks
        @@logger = Log4r::Logger.new("vagrant::guest::darwin::configure_networks")

        include Vagrant::Util

        def self.configure_networks(machine, networks)
          if !machine.provider.capability?(:nic_mac_addresses)
            raise Vagrant::Errors::CantReadMACAddresses,
                  provider: machine.provider_name.to_s
          end

          nic_mac_addresses = machine.provider.capability(:nic_mac_addresses)
          @@logger.debug("mac addresses: #{nic_mac_addresses.inspect}")

          mac_service_map = create_mac_service_map(machine)

          networks.each do |network|
            mac_address = nic_mac_addresses[network[:interface]+1]
            if mac_address.nil?
              @@logger.warn("Could not find mac address for network #{network.inspect}")
              next
            end

            service_name = mac_service_map[mac_address]
            if service_name.nil?
              @@logger.warn("Could not find network service for mac address #{mac_address}")
              next
            end

            network_type = network[:type].to_sym
            case network_type.to_sym
            when :static
              command = "networksetup -setmanual \"#{service_name}\" #{network[:ip]} #{network[:netmask]} #{network[:router]}"
            when :static6
              command = "networksetup -setv6manual \"#{service_name}\" #{network[:ip]} #{network[:netmask]} #{network[:router]}"
            when :dhcp
              command = "networksetup -setdhcp \"#{service_name}\""
            when :dhcp6
              # This is not actually possible yet in Vagrant, but when we do
              # enable IPv6 across the board, Darwin will already have support.
              command = "networksetup -setv6automatic \"#{service_name}\""
            else
              raise Vagrant::Errors::NetworkTypeNotSupported, type: network_type
            end

            machine.communicate.sudo(command)
          end
        end

        # Creates a hash mapping MAC addresses to network service name
        # Example: { "00C100A1B2C3" => "Thunderbolt Ethernet" }
        def self.create_mac_service_map(machine)
          tmp_ints = File.join(Dir.tmpdir, File.basename("#{machine.id}.interfaces"))
          tmp_hw = File.join(Dir.tmpdir, File.basename("#{machine.id}.hardware"))

          machine.communicate.tap do |comm|
            comm.sudo("networksetup -detectnewhardware")
            comm.sudo("networksetup -listnetworkserviceorder > /tmp/vagrant.interfaces")
            comm.sudo("networksetup -listallhardwareports > /tmp/vagrant.hardware")
            comm.download("/tmp/vagrant.interfaces", tmp_ints)
            comm.download("/tmp/vagrant.hardware", tmp_hw)
          end

          interface_map = {}
          ints = ::IO.read(tmp_ints)
          ints.split(/\n\n/m).each do |i|
            if i.match(/Hardware/) && i.match(/Ethernet/)
              # Ethernet, should be 2 lines,
              # (3) Thunderbolt Ethernet
              # (Hardware Port: Thunderbolt Ethernet, Device: en1)

              # multiline, should match "Thunderbolt Ethernet", "en1"
              devicearry = i.match(/\([0-9]+\) (.+)\n.*Device: (.+)\)/m)
              service = devicearry[1]
              interface = devicearry[2]

              # Should map interface to service { "en1" => "Thunderbolt Ethernet" }
              interface_map[interface] = service
            end
          end
          File.delete(tmp_ints)

          mac_service_map = {}
          macs = ::IO.read(tmp_hw)
          macs.split(/\n\n/m).each do |i|
            if i.match(/Hardware/) && i.match(/Ethernet/)
              # Ethernet, should be 3 lines,
              # Hardware Port: Thunderbolt 1
              # Device: en1
              # Ethernet Address: a1:b2:c3:d4:e5:f6

              # multiline, should match "en1", "00:c1:00:a1:b2:c3"
              devicearry = i.match(/Device: (.+)\nEthernet Address: (.+)/m)
              interface = devicearry[1]
              naked_mac = devicearry[2].gsub(':','').upcase

              # Skip hardware ports without MAC (bridges, bluetooth, etc.)
              next if naked_mac == "N/A"

              if !interface_map[interface]
                @@logger.warn("Could not find network service for interface #{interface}")
                next
              end

              # Should map MAC to service, { "00C100A1B2C3" => "Thunderbolt Ethernet" }
              mac_service_map[naked_mac] = interface_map[interface]
            end
          end
          File.delete(tmp_hw)

          mac_service_map
        end
      end
    end
  end
end
