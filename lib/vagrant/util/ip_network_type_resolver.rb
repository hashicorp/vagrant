require "ipaddr"
require_relative "../errors"

module Vagrant
  module Util
    class IpNetworkTypeResolver
      def self.resolve(ip)
        begin
          ipaddr = IPAddr.new(ip)
          if ipaddr.ipv4?
            :static
          else
            :static6
          end
        rescue IPAddr::Error => e
          raise Vagrant::Errors::NetworkAddressInvalid,
            address: ip
        end
      end
    end
  end
end