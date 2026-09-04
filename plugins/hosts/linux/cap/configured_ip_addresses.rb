require "socket"

module VagrantPlugins
  module HostLinux
    module Cap
      class ConfiguredIPAddresses
        def self.configured_ip_addresses(env)
          Socket.getifaddrs.map do |interface|
            # NB we must check for nil because some interfaces managed by
            #    wireguard might not have an address.
            if interface.addr != nil && interface.addr.ipv4? && !interface.addr.ipv4_loopback?
              interface.addr.ip_address
            end
          end.compact
        end
      end
    end
  end
end
