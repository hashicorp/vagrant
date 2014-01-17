require "ipaddr"

module VagrantPlugins
  module GuestTinyCore
    module Cap
      class ConfigureNetworks
        def self.configure_networks(machine, networks)
          machine.communicate.tap do |comm|
            networks.each do |n|
              ifc = "/sbin/ifconfig eth#{n[:interface]}"
              broadcast = (IPAddr.new(n[:ip]) | (~ IPAddr.new(n[:netmask]))).to_s
              comm.sudo("#{ifc} down")
              comm.sudo("#{ifc} #{n[:ip]} netmask #{n[:netmask]} broadcast #{broadcast}")
              comm.sudo("#{ifc} up")
            end
          end
        end
      end
    end
  end
end
