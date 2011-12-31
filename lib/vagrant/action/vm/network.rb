require 'log4r'

module Vagrant
  module Action
    module VM
      # Networking middleware for Vagrant. This enables host only
      # networking on VMs if configured as such.
      class Network
        def initialize(app, env)
          @logger = Log4r::Logger.new("vagrant::action::vm::network")

          @app = app
        end

        def call(env)
          @env = env

          networks = host_only_networks
          @logger.debug("Must configure #{networks.length} host only networks")

          # Verify that none of the networks collide with a bridged
          # interface, because this will cause problems.
          networks.each do |network_options|
            raise Errors::NetworkCollision if !verify_no_bridge_collision(network_options)
          end

          # Create the network interfaces on the VM if we need to
          assign_network(networks) if !networks.empty?

          @app.call(env)

          # Enable the network interfaces
          if !networks.empty?
            @env[:ui].info I18n.t("vagrant.actions.vm.network.enabling")

            # Prepare for new networks...
            networks.each do |network_options|
              @env[:vm].guest.prepare_host_only_network(network_options)
            end

            # Then enable the networks...
            networks.each do |network_options|
              @env[:vm].guest.enable_host_only_network(network_options)
            end
          end
        end

        # Returns an array of the network options for host only networks.
        def host_only_networks
          results = []
          @env[:vm].config.vm.networks.each do |type, args|
            if type == :hostonly
              ip      = args[0]
              options = args[1] || {}

              results << {
                :ip      => ip,
                :netmask => "255.255.255.0",
                :adapter => 1,
                :mac     => nil,
                :name    => nil
              }.merge(options)
            end
          end

          results
        end

        # Verifies that there is no collision with a bridged network interface
        # for the given network options.
        def verify_no_bridge_collision(net_options)
          @env[:vm].driver.read_bridged_interfaces.each do |interface|
            return false if matching_network?(interface, net_options)
          end

          true
        end

        # Enables and assigns the host only network to the proper
        # adapter on the VM, and saves the adapter.
        def assign_network(networks)
          @env[:ui].info I18n.t("vagrant.actions.vm.network.preparing")

          host_only_interfaces = @env[:vm].driver.read_host_only_interfaces
          adapters = []

          # Build the networks and the list of adapters we need to enable
          networks.each do |network_options|
            @logger.debug("Searching for matching network: #{network_options[:ip]}")
            interface = find_matching_network(host_only_interfaces, network_options)

            if !interface
              @logger.debug("Network not found. Creating if we can.")

              # It is an error case if a specific name was given but the network
              # doesn't exist.
              if network_options[:name]
                raise Errors::NetworkNotFound, :name => network_options[:name]
              end

              # Otherwise, we create a new network and put the net network
              # in the list of available networks so other network definitions
              # can use it!
              interface = create_network(network_options)
              host_only_interfaces << interface

              @logger.debug("Created network: #{interface[:name]}")
            end

            adapters << {
              :adapter  => network_options[:adapter] + 1,
              :type     => :hostonly,
              :hostonly => interface[:name],
              :mac_address => network_options[:mac]
            }
          end

          # Enable the host only adapters!
          @logger.info("Enabling host only network adapters")
          @env[:vm].driver.enable_adapters(adapters)
        end

        # This looks through a list of available host only networks and
        # finds a matching network.
        #
        # If one is not available, `nil` is returned.
        def find_matching_network(networks, needle_options)
          networks.each do |network|
            if needle_options[:name] && needle_options[:name] == network[:name]
              return network
            elsif matching_network?(network, needle_options)
              return network
            end
          end

          nil
        end

        # Creates a host only network with the given options and returns
        # the hash of the options it was created with.
        #
        # @return [Hash]
        def create_network(network_options)
          # Create the options for the host only network, specifically
          # figuring out the host only network IP based on the netmask.
          options = network_options.merge({
            :ip => network_ip(network_options[:ip], network_options[:netmask])
          })

          @env[:vm].driver.create_host_only_network(options)
        end

        # Tests if a network matches the given options by applying the
        # netmask to the IP of the network and also to the IP of the
        # virtual machine and see if they match.
        def matching_network?(interface, net_options)
          interface[:netmask] == net_options[:netmask] &&
            apply_netmask(interface[:ip], interface[:netmask]) ==
            apply_netmask(net_options[:ip], net_options[:netmask])
        end

        # Applies a netmask to an IP and returns the corresponding
        # parts.
        def apply_netmask(ip, netmask)
          ip = split_ip(ip)
          netmask = split_ip(netmask)

          ip.map do |part|
            part & netmask.shift
          end
        end

        # Splits an IP and converts each portion into an int.
        def split_ip(ip)
          ip.split(".").map do |i|
            i.to_i
          end
        end

        # Returns a "network IP" which is a "good choice" for the IP
        # for the actual network based on the netmask.
        def network_ip(ip, netmask)
          parts = apply_netmask(ip, netmask)
          parts[3] += 1;
          parts.join(".")
        end
      end
    end
  end
end
