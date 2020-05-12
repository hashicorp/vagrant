module Vagrant
  module Util
    module IPv4Interfaces
      def self.ipv4_interfaces
        Socket.getifaddrs.select do |ifaddr|
          ifaddr.addr && ifaddr.addr.ipv4?
        end.map do |ifaddr|
          [ifaddr.name, ifaddr.addr.ip_address]
        end
      end
    end
  end
end
