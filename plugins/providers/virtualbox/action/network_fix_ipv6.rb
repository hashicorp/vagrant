require "ipaddr"
require "socket"

require "log4r"

require "vagrant/util/scoped_hash_override"

module VagrantPlugins
  module ProviderVirtualBox
    module Action
      # This middleware works around a bug in VirtualBox where booting
      # a VM with an IPv6 host-only network will someties lose the
      # route to that machine.
      class NetworkFixIPv6
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
            next if options[:ip] == ""
            if IPAddr.new(options[:ip]).ipv6?
              has_v6 = true
              break
            end
          end

          # Call up
          @app.call(env)

          # If we have no IPv6, forget it
          return if !has_v6

          # We do, so fix them if we must
          env[:machine].provider.driver.read_host_only_interfaces.each do |interface|
            # Ignore interfaces without an IPv6 address
            next if interface[:ipv6] == ""

            # Make the test IP. This is just the highest value IP
            ip = IPAddr.new(interface[:ipv6])
            ip |= IPAddr.new(":#{":FFFF" * (interface[:ipv6_prefix].to_i / 16)}")

            @logger.info("testing IPv6: #{ip}")
            begin
              UDPSocket.new(Socket::AF_INET6).connect(ip.to_s, 80)
            rescue Errno::EHOSTUNREACH
              @logger.info("IPv6 host unreachable. Fixing: #{ip}")
              env[:machine].provider.driver.reconfig_host_only(interface)
            end
          end
        end
      end
    end
  end
end
