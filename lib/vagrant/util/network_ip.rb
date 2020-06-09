require "ipaddr"

module Vagrant
  module Util
    module NetworkIP

      DEFAULT_MASK = "255.255.255.0".freeze

      LOGGER = Log4r::Logger.new("vagrant::util::NetworkIP")

      # Returns the network address of the given IP and subnet.
      #
      # @return [String]
      def network_address(ip, subnet)
        begin
          IPAddr.new(ip).mask(subnet).to_s
        rescue IPAddr::InvalidPrefixError
          LOGGER.warn("Provided mask '#{subnet}' is invalid. Falling back to using mask '#{DEFAULT_MASK}'")
          IPAddr.new(ip).mask(DEFAULT_MASK).to_s
        end
      end
    end
  end
end
