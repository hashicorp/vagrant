module Vagrant
  module Util
    module IPv4Interfaces
      def ipv4_interfaces
        Socket.getifaddrs.select do |ifaddr|
          ifaddr.addr && ifaddr.addr.ipv4?
        end.map do |ifaddr|
          [ifaddr.name, ifaddr.addr.ip_address]
        end
      end

      extend IPv4Interfaces
    end
  end
end
