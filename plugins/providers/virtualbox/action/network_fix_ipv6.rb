require "ipaddr"
require "socket"

require "log4r"

require "vagrant/util/presence"
require "vagrant/util/scoped_hash_override"

module VagrantPlugins
  module ProviderVirtualBox
    module Action
      # This middleware works around a bug in VirtualBox where booting
      # a VM with an IPv6 host-only network will someties lose the
      # route to that machine.
      class NetworkFixIPv6
        include Vagrant::Util::Presence
        include Vagrant::Util::ScopedHashOverride

        def initialize(app, env)
          @logger = Log4r::Logger.new("vagrant::plugins::virtualbox::network")
          @app    = app
        end

        def call(env)
          @env = env

          # Determine if we have an IPv6 network
          has_v6 = false
          env[:machine].config.vm.networks.each do |type, options|
            next if type != :private_network
            options = scoped_hash_override(options, :virtualbox)
            next if options[:ip].to_s.strip == ""

            if IPAddr.new(options[:ip]).ipv6?
              has_v6 = true
              break
            end
          end

          # Call up
          @app.call(env)

          # If we have no IPv6, forget it
          return if !has_v6

          networks(env).each do |network|
            next if !present?(network[:ipv6])
            next if network[:status] != "Up"

            ip = IPAddr.new(network[:ipv6])
            ip |= ("1" * (128 - network[:ipv6_prefix].to_i)).to_i(2)

            @logger.info("testing IPv6: #{ip}")

            begin
              UDPSocket.new(Socket::AF_INET6).connect(ip.to_s, 80)
            rescue Errno::EHOSTUNREACH
              @logger.info("IPv6 host unreachable. Fixing: #{ip}")
              env[:machine].provider.driver.reconfig_host_only(network)
            end
          end
        end

        # The list of interface names for host-only adapters.
        # @return [Array<String>]
        def host_only_interface_names(env)
          env[:machine].provider.driver.read_network_interfaces
            .map { |_, i| i[:hostonly] if i[:type] == :hostonly }.compact
        end

        # The list of networks that are tied to a host-only adapter.
        # @return [Array]
        def networks(env)
          iface_names = self.host_only_interface_names(env)
          env[:machine].provider.driver.read_host_only_interfaces
            .select { |network| iface_names.include?(network[:name]) }
        end
      end
    end
  end
end
