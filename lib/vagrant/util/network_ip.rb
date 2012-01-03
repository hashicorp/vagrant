module Vagrant
  module Util
    module NetworkIP
      # Returns the network address of the given IP and subnet.
      #
      # @return [String]
      def network_address(ip, subnet)
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
