require "ipaddr"

module Vagrant
  module Util
    module NetworkIP
      # Returns the network address of the given IP and subnet.
      #
      # If the IP address is an IPv6 address, subnet should be a prefix
      # length such as "64".
      #
      # @return [String]
      def network_address(ip, subnet)
        # If this is an IPv6 address, then just mask it
        if subnet.to_s =~ /^\d+$/
          ip = IPAddr.new(ip)
          return ip.mask(subnet.to_i).to_s
        end

        ip      = ip_parts(ip)
        netmask = ip_parts(subnet)

        # Bitwise-AND each octet to get the network address
        # in octets and join each part with a period to get
        # the resulting network address.
        ip.map { |part| part & netmask.shift }.join(".")
      end

      protected

      # Splits an IP into the four octets and returns each as an
      # integer in an array.
      #
      # @return [Array<Integer>]
      def ip_parts(ip)
        ip.split(".").map { |i| i.to_i }
      end
    end
  end
end
