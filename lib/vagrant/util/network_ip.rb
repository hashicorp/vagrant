require "ipaddr"

module Vagrant
  module Util
    module NetworkIP
      # Returns the network address of the given IP and subnet.
      #
      # @return [String]
      def network_address(ip, subnet)
        IPAddr.new(ip).mask(subnet).to_s
      end
    end
  end
end
