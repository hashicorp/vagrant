require 'ipaddr'
require 'log4r'

require 'vagrant/util/scoped_hash_override'

module VagrantPlugins
  module DockerProvider
    module Action
      class PrepareNetworks

        include Vagrant::Util::ScopedHashOverride

        @@lock = Mutex.new

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant::plugins::docker::preparenetworks')
        end

        # Generate CLI arguments for creating the docker network.
        #
        # @param [Hash] options Options from the network config
        # @returns[Array<String>] Network create arguments
        def generate_create_cli_arguments(options)
          options.map do |key, value|
            # If value is false, option is not set
            next if value.to_s == "false"
            # If value is true, consider feature flag with no value
            opt = value.to_s == "true" ? [] : [value]
            opt.unshift("--#{key.to_s.tr("_", "-")}")
          end.flatten.compact
        end

        # @return [Array<Socket::Ifaddr>] interface list
        def list_interfaces
          Socket.getifaddrs.find_all do |i|
            !i.addr.nil? && i.addr.ip? && !i.addr.ipv4_loopback? &&
              !i.addr.ipv6_loopback? && !i.addr.ipv6_linklocal?
          end
        end

        # Validates that a network name exists. If it does not
        # exist, an exception is raised.
        #
        # @param [String] network_name Name of existing network
        # @param [Hash] env Local call env
        # @return [Boolean]
        def validate_network_name!(network_name, env)
          if !env[:machine].provider.driver.existing_named_network?(network_name)
            raise Errors::NetworkNameUndefined,
              network_name: network_name
          end
          true
        end

        # Validates that the provided options are compatible with a
        # pre-existing network. Raises exceptions on invalid configurations
        #
        # @param [String] network_name Name of the network
        # @param [Hash] root_options Root networking options
        # @param [Hash] network_options Docker scoped networking options
        # @param [Driver] driver Docker driver
        # @return [Boolean]
        def validate_network_configuration!(network_name, root_options, network_options, driver)
          if root_options[:ip] &&
              driver.network_containing_address(root_options[:ip]) != network_name
            raise Errors::NetworkAddressInvalid,
              address: root_options[:ip],
              network_name: network_name
          end
          if network_options[:subnet] &&
              driver.network_containing_address(network_options[:subnet]) != network_name
            raise Errors::NetworkSubnetInvalid,
              subnet: network_options[:subnet],
              network_name: network_name
          end
          true
        end

        # Generate configuration for private network
        #
        # @param [Hash] root_options Root networking options
        # @param [Hash] net_options Docker scoped networking options
        # @param [Hash] env Local call env
        # @return [String, Hash] Network name and updated network_options
        def process_private_network(root_options, network_options, env)
          if root_options[:name] && validate_network_name!(root_options[:name], env)
            network_name = root_options[:name]
          end

          if root_options[:type].to_s == "dhcp"
            if !root_options[:ip] && !root_options[:subnet]
              network_name = "vagrant_network" if !network_name
              return [network_name, network_options]
            end
            if root_options[:subnet]
              addr = IPAddr.new(root_options[:subnet])
              root_options[:netmask] = addr.prefix
            end
          end

          if root_options[:ip]
            addr = IPAddr.new(root_options[:ip])
          elsif addr.nil?
            raise Errors::NetworkIPAddressRequired
          end

          # If address is ipv6, enable ipv6 support
          network_options[:ipv6] = addr.ipv6?

          # If no mask is provided, attempt to locate any existing
          # network which contains the assigned IP address
          if !root_options[:netmask] && !network_name
            network_name = env[:machine].provider.driver.
              network_containing_address(root_options[:ip])
            # When no existing network is found, we are creating
            # a new network. Since no mask was provided, default
            # to /24 for ipv4 and /64 for ipv6
            if !network_name
              root_options[:netmask] = addr.ipv4? ? 24 : 64
            end
          end

          # With no network name, process options to find or determine
          # name for new network
          if !network_name
            if !root_options[:subnet]
              # Only generate a subnet if not given one
              subnet = IPAddr.new("#{addr}/#{root_options[:netmask]}")
              network = "#{subnet}/#{root_options[:netmask]}"
            else
              network = root_options[:subnet]
            end

            network_options[:subnet] = network
            existing_network = env[:machine].provider.driver.
              network_defined?(network)

            if !existing_network
              network_name = "vagrant_network_#{network}"
            else
              if !existing_network.to_s.start_with?("vagrant_network")
                env[:ui].warn(I18n.t("docker_provider.subnet_exists",
                  network_name: existing_network,
                  subnet: network))
              end
              network_name = existing_network
            end
          end

          [network_name, network_options]
        end

        # Generate configuration for public network
        #
        # TODO: When the Vagrant installer upgrades to Ruby 2.5.x,
        # remove all instances of the roundabout way of determining a prefix
        # and instead just use the built-in `.prefix` method
        #
        # @param [Hash] root_options Root networking options
        # @param [Hash] net_options Docker scoped networking options
        # @param [Hash] env Local call env
        # @return [String, Hash] Network name and updated network_options
        def process_public_network(root_options, net_options, env)
          if root_options[:name] && validate_network_name!(root_options[:name], env)
            network_name = root_options[:name]
          end
          if !network_name
            valid_interfaces = list_interfaces
            if valid_interfaces.empty?
              raise Errors::NetworkNoInterfaces
            elsif valid_interfaces.size == 1
              bridge_interface = valid_interfaces.first
            elsif i = valid_interfaces.detect{|i| Array(root_options[:bridge]).include?(i.name) }
              bridge_interface = i
            end
            if !bridge_interface
              env[:ui].info(I18n.t("vagrant.actions.vm.bridged_networking.available"),
                prefix: false)
              valid_interfaces.each_with_index do |int, i|
                env[:ui].info("#{i + 1}) #{int.name}", prefix: false)
              end
              env[:ui].info(I18n.t(
                "vagrant.actions.vm.bridged_networking.choice_help") + "\n",
                prefix: false
              )
            end
            while !bridge_interface
              choice = env[:ui].ask(
                I18n.t("vagrant.actions.vm.bridged_networking.select_interface") + " ",
                prefix: false)
              bridge_interface = valid_interfaces[choice.to_i - 1]
            end
            base_opts = Vagrant::Util::HashWithIndifferentAccess.new
            base_opts[:opt] = "parent=#{bridge_interface.name}"
            subnet = IPAddr.new(bridge_interface.addr.ip_address <<
              "/" << bridge_interface.netmask.ip_unpack.first)
            netmask = bridge_interface.netmask.ip_unpack.first
            prefix = IPAddr.new("255.255.255.255/#{netmask}").to_i.to_s(2).count("1")
            base_opts[:subnet] = "#{subnet}/#{prefix}"
            subnet_addr = IPAddr.new(base_opts[:subnet])
            base_opts[:driver] = "macvlan"
            base_opts[:gateway] = subnet_addr.succ.to_s
            base_opts[:ipv6] = subnet_addr.ipv6?
            network_options = base_opts.merge(net_options)

            # Check if network already exists for this subnet
            network_name = env[:machine].provider.driver.
              network_containing_address(network_options[:gateway])
            if !network_name
              network_name = "vagrant_network_public_#{bridge_interface.name}"
            end

            # If the network doesn't already exist, gather available address range
            # within subnet which docker can provide addressing
            if !env[:machine].provider.driver.existing_named_network?(network_name)
              if !net_options[:gateway]
                network_options[:gateway] = request_public_gateway(
                  network_options, bridge_interface.name, env)
              end
              network_options[:ip_range] = request_public_iprange(
                network_options, bridge_interface, env)
            end
          end
          [network_name, network_options]
        end

        # Request the gateway address for the public network
        #
        # @param [Hash] network_options Docker scoped networking options
        # @param [String] interface The bridge interface used
        # @param [Hash] env Local call env
        # @return [String] Gateway address
        def request_public_gateway(network_options, interface, env)
          subnet = IPAddr.new(network_options[:subnet])
          gateway = nil
          while !gateway
            gateway = env[:ui].ask(I18n.t(
              "docker_provider.network_bridge_gateway_request",
              interface: interface,
              default_gateway: network_options[:gateway]) + " ",
              prefix: false
            ).strip
            if gateway.empty?
              gateway = network_options[:gateway]
            end
            begin
              gateway = IPAddr.new(gateway)
              if !subnet.include?(gateway)
                env[:ui].warn(I18n.t("docker_provider.network_bridge_gateway_outofbounds",
                  gateway: gateway,
                  subnet: network_options[:subnet]) + "\n", prefix: false)
              end
            rescue IPAddr::InvalidAddressError
              env[:ui].warn(I18n.t("docker_provider.network_bridge_gateway_invalid",
                gateway: gateway) + "\n", prefix: false)
              gateway = nil
            end
          end
          gateway.to_s
        end

        # Request the IP range allowed for use by docker when creating a new
        # public network
        #
        # TODO: When the Vagrant installer upgrades to Ruby 2.5.x,
        # remove all instances of the roundabout way of determining a prefix
        # and instead just use the built-in `.prefix` method
        #
        # @param [Hash] network_options Docker scoped networking options
        # @param [Socket::Ifaddr] interface The bridge interface used
        # @param [Hash] env Local call env
        # @return [String] Address range
        def request_public_iprange(network_options, interface, env)
          return network_options[:ip_range] if network_options[:ip_range]
          subnet = IPAddr.new(network_options[:subnet])
          env[:ui].info(I18n.t(
            "docker_provider.network_bridge_iprange_info") + "\n",
            prefix: false
          )
          range = nil
          while !range
            range = env[:ui].ask(I18n.t(
              "docker_provider.network_bridge_iprange_request",
              interface: interface.name,
              default_range: network_options[:subnet]) + " ",
              prefix: false
            ).strip
            if range.empty?
              range = network_options[:subnet]
            end
            begin
              range = IPAddr.new(range)
              if !subnet.include?(range)
                netmask = interface.netmask.ip_unpack.first
                prefix = IPAddr.new("255.255.255.255/#{netmask}").to_i.to_s(2).count("1")
                env[:ui].warn(I18n.t(
                  "docker_provider.network_bridge_iprange_outofbounds",
                  subnet: network_options[:subnet],
                  range: "#{range}/#{prefix}"
                ) + "\n", prefix: false)
                range = nil
              end
            rescue IPAddr::InvalidAddressError
              env[:ui].warn(I18n.t(
                "docker_provider.network_bridge_iprange_invalid",
                range: range) + "\n", prefix: false)
              range = nil
            end
          end

          netmask = interface.netmask.ip_unpack.first
          prefix = IPAddr.new("255.255.255.255/#{netmask}").to_i.to_s(2).count("1")
          "#{range}/#{prefix}"
        end

        # Execute the action
        def call(env)
          # If we are using a host VM, then don't worry about it
          machine = env[:machine]
          if machine.provider.host_vm?
            @logger.debug("Not setting up networks because docker host_vm is in use")
            return @app.call(env)
          end

          connections = {}
          @@lock.synchronize do
            machine.env.lock("docker-network-create", retry: true) do
              env[:ui].info(I18n.t("docker_provider.network_create"))
              machine.config.vm.networks.each_with_index do |net_info, net_idx|
                type, options = net_info
                network_options = scoped_hash_override(options, :docker_network)
                network_options.delete_if{|k,_| options.key?(k)}

                case type
                when :public_network
                  network_name, network_options = process_public_network(
                    options, network_options, env)
                when :private_network
                  network_name, network_options = process_private_network(
                    options, network_options, env)
                else
                  next # unsupported type so ignore
                end

                if !network_name
                  raise Errors::NetworkInvalidOption, container: machine.name
                end

                if !machine.provider.driver.existing_named_network?(network_name)
                  @logger.debug("Creating network #{network_name}")
                  cli_opts = generate_create_cli_arguments(network_options)
                  machine.provider.driver.create_network(network_name, cli_opts)
                else
                  @logger.debug("Network #{network_name} already created")
                  validate_network_configuration!(network_name, options, network_options, machine.provider.driver)
                end
                connections[net_idx] = network_name
              end
            end
          end

          env[:docker_connects] = connections
          @app.call(env)
        end
      end
    end
  end
end
