require "set"

require "log4r"

require "vagrant/util/network_ip"
require "vagrant/util/scoped_hash_override"

module VagrantPlugins
  module ProviderVirtualBox
    module Action
      # This middleware class sets up all networking for the VirtualBox
      # instance. This includes host only networks, bridged networking,
      # forwarded ports, etc.
      #
      # This handles all the `config.vm.network` configurations.
      class Network
        include Vagrant::Util::NetworkIP
        include Vagrant::Util::ScopedHashOverride

        def initialize(app, env)
          @logger = Log4r::Logger.new("vagrant::plugins::virtualbox::network")
          @app    = app
        end

        def call(env)
          # TODO: Validate network configuration prior to anything below
          @env = env

          # Get the list of network adapters from the configuration
          network_adapters_config = env[:machine].provider_config.network_adapters.dup

          # Assign the adapter slot for each high-level network
          available_slots = Set.new(1..36)
          network_adapters_config.each do |slot, _data|
            available_slots.delete(slot)
          end

          @logger.debug("Available slots for high-level adapters: #{available_slots.inspect}")
          @logger.info("Determining network adapters required for high-level configuration...")
          available_slots = available_slots.to_a.sort
          env[:machine].config.vm.networks.each do |type, options|
            # We only handle private and public networks
            next if type != :private_network && type != :public_network

            options = scoped_hash_override(options, :virtualbox)

            # Figure out the slot that this adapter will go into
            slot = options[:adapter]
            if !slot
              if available_slots.empty?
                raise Vagrant::Errors::VirtualBoxNoRoomForHighLevelNetwork
              end

              slot = available_slots.shift
            end

            # Internal network is a special type
            if type == :private_network && options[:intnet]
              type = :internal_network
            end

            # Configure it
            data = nil
            if type == :private_network
              # private_network = hostonly
              data = [:hostonly, options]
            elsif type == :public_network
              # public_network = bridged
              data = [:bridged, options]
            elsif type == :internal_network
              data = [:intnet, options]
            end

            # Store it!
            @logger.info(" -- Slot #{slot}: #{data[0]}")
            network_adapters_config[slot] = data
          end

          @logger.info("Determining adapters and compiling network configuration...")
          adapters = []
          networks = []
          network_adapters_config.each do |slot, data|
            type    = data[0]
            options = data[1]

            @logger.info("Network slot #{slot}. Type: #{type}.")

            # Get the normalized configuration for this type
            config = send("#{type}_config", options)
            config[:adapter] = slot
            @logger.debug("Normalized configuration: #{config.inspect}")

            # Get the VirtualBox adapter configuration
            adapter = send("#{type}_adapter", config)
            adapters << adapter
            @logger.debug("Adapter configuration: #{adapter.inspect}")

            # Get the network configuration
            network = send("#{type}_network_config", config)
            network[:auto_config] = config[:auto_config]
            networks << network
          end

          if !adapters.empty?
            # Enable the adapters
            @logger.info("Enabling adapters...")
            env[:ui].output(I18n.t("vagrant.actions.vm.network.preparing"))
            adapters.each do |adapter|
              env[:ui].detail(I18n.t(
                "vagrant.virtualbox.network_adapter",
                adapter: adapter[:adapter].to_s,
                type: adapter[:type].to_s,
                extra: "",
              ))
            end

            env[:machine].provider.driver.enable_adapters(adapters)
          end

          # Continue the middleware chain.
          @app.call(env)

          # If we have networks to configure, then we configure it now, since
          # that requires the machine to be up and running.
          if !adapters.empty? && !networks.empty?
            assign_interface_numbers(networks, adapters)

            # Only configure the networks the user requested us to configure
            networks_to_configure = networks.select { |n| n[:auto_config] }
            if !networks_to_configure.empty?
              env[:ui].info I18n.t("vagrant.actions.vm.network.configuring")
              env[:machine].guest.capability(:configure_networks, networks_to_configure)
            end
          end
        end

        def bridged_config(options)
          return {
            auto_config:                     true,
            bridge:                          nil,
            mac:                             nil,
            nic_type:                        nil,
            use_dhcp_assigned_default_route: false
          }.merge(options || {})
        end

        def bridged_adapter(config)
          # Find the bridged interfaces that are available
          bridgedifs = @env[:machine].provider.driver.read_bridged_interfaces
          bridgedifs.delete_if { |interface| interface[:status] == "Down" }

          # The name of the chosen bridge interface will be assigned to this
          # variable.
          chosen_bridge = nil

          if config[:bridge]
            @logger.debug("Bridge was directly specified in config, searching for: #{config[:bridge]}")

            # Search for a matching bridged interface
            Array(config[:bridge]).each do |bridge|
              bridge = bridge.downcase if bridge.respond_to?(:downcase)
              bridgedifs.each do |interface|
                if bridge === interface[:name].downcase
                  @logger.debug("Specific bridge found as configured in the Vagrantfile. Using it.")
                  chosen_bridge = interface[:name]
                  break
                end
              end
              break if chosen_bridge
            end

            # If one wasn't found, then we notify the user here.
            if !chosen_bridge
              @env[:ui].info I18n.t("vagrant.actions.vm.bridged_networking.specific_not_found",
                                    bridge: config[:bridge])
            end
          end

          # If we still don't have a bridge chosen (this means that one wasn't
          # specified in the Vagrantfile, or the bridge specified in the Vagrantfile
          # wasn't found), then we fall back to the normal means of searchign for a
          # bridged network.
          if !chosen_bridge
            if bridgedifs.length == 1
              # One bridgable interface? Just use it.
              chosen_bridge = bridgedifs[0][:name]
              @logger.debug("Only one bridged interface available. Using it by default.")
            else
              # More than one bridgable interface requires a user decision, so
              # show options to choose from.
              @env[:ui].info I18n.t(
                "vagrant.actions.vm.bridged_networking.available",
                prefix: false)
              bridgedifs.each_index do |index|
                interface = bridgedifs[index]
                @env[:ui].info("#{index + 1}) #{interface[:name]}", prefix: false)
              end
              @env[:ui].info(I18n.t(
                "vagrant.actions.vm.bridged_networking.choice_help")+"\n")

              # The range of valid choices
              valid = Range.new(1, bridgedifs.length)

              # The choice that the user has chosen as the bridging interface
              choice = nil
              while !valid.include?(choice)
                choice = @env[:ui].ask(
                  "Which interface should the network bridge to? ")
                choice = choice.to_i
              end

              chosen_bridge = bridgedifs[choice - 1][:name]
            end
          end

          @logger.info("Bridging adapter #{config[:adapter]} to #{chosen_bridge}")

          # Given the choice we can now define the adapter we're using
          return {
            adapter:     config[:adapter],
            type:        :bridged,
            bridge:      chosen_bridge,
            mac_address: config[:mac],
            nic_type:    config[:nic_type]
          }
        end

        def bridged_network_config(config)
          if config[:ip]
            options = {
                auto_config: true,
                mac:         nil,
                netmask:     "255.255.255.0",
                type:        :static
            }.merge(config)
            options[:type] = options[:type].to_sym
            return options
          end

          return {
            type: :dhcp,
            use_dhcp_assigned_default_route: config[:use_dhcp_assigned_default_route]
          }
        end

        def hostonly_config(options)
          options = {
            auto_config: true,
            mac:         nil,
            nic_type:    nil,
            netmask:     "255.255.255.0",
            type:        :static
          }.merge(options)

          # Make sure the type is a symbol
          options[:type] = options[:type].to_sym

          # Default IP is in the 20-bit private network block for DHCP based networks
          options[:ip] = "172.28.128.1" if options[:type] == :dhcp && !options[:ip]

          # Calculate our network address for the given IP/netmask
          netaddr  = network_address(options[:ip], options[:netmask])

          # Verify that a host-only network subnet would not collide
          # with a bridged networking interface.
          #
          # If the subnets overlap in any way then the host only network
          # will not work because the routing tables will force the
          # traffic onto the real interface rather than the VirtualBox
          # interface.
          @env[:machine].provider.driver.read_bridged_interfaces.each do |interface|
            that_netaddr = network_address(interface[:ip], interface[:netmask])
            raise Vagrant::Errors::NetworkCollision if \
              netaddr == that_netaddr && interface[:status] != "Down"
          end

          # Split the IP address into its components
          ip_parts = netaddr.split(".").map { |i| i.to_i }

          # Calculate the adapter IP, which we assume is the IP ".1" at
          # the end usually.
          adapter_ip    = ip_parts.dup
          adapter_ip[3] += 1
          options[:adapter_ip] ||= adapter_ip.join(".")

          dhcp_options = {}
          if options[:type] == :dhcp
            # Calculate the DHCP server IP, which is the network address
            # with the final octet + 2. So "172.28.0.0" turns into "172.28.0.2"
            dhcp_ip    = ip_parts.dup
            dhcp_ip[3] += 2
            dhcp_options[:dhcp_ip] = options[:dhcp_ip] || dhcp_ip.join(".")

            # Calculate the lower and upper bound for the DHCP server
            dhcp_lower    = ip_parts.dup
            dhcp_lower[3] += 3
            dhcp_options[:dhcp_lower] = options[:dhcp_lower] || dhcp_lower.join(".")

            dhcp_upper    = ip_parts.dup
            dhcp_upper[3] = 254
            dhcp_options[:dhcp_upper] = options[:dhcp_upper] || dhcp_upper.join(".")
          end

          return {
            adapter_ip:  options[:adapter_ip],
            auto_config: options[:auto_config],
            ip:          options[:ip],
            mac:         options[:mac],
            name:        options[:name],
            netmask:     options[:netmask],
            nic_type:    options[:nic_type],
            type:        options[:type]
          }.merge(dhcp_options)
        end

        def hostonly_adapter(config)
          @logger.info("Searching for matching hostonly network: #{config[:ip]}")
          interface = hostonly_find_matching_network(config)

          if !interface
            @logger.info("Network not found. Creating if we can.")

            # It is an error if a specific host only network name was specified
            # but the network wasn't found.
            if config[:name]
              raise Vagrant::Errors::NetworkNotFound, name: config[:name]
            end

            # Create a new network
            interface = hostonly_create_network(config)
            @logger.info("Created network: #{interface[:name]}")
          end

          if config[:type] == :dhcp
            create_dhcp_server_if_necessary(interface, config)
          end

          return {
            adapter:     config[:adapter],
            hostonly:    interface[:name],
            mac_address: config[:mac],
            nic_type:    config[:nic_type],
            type:        :hostonly
          }
        end

        def hostonly_network_config(config)
          return {
            type:       config[:type],
            adapter_ip: config[:adapter_ip],
            ip:         config[:ip],
            netmask:    config[:netmask]
          }
        end

        def intnet_config(options)
          return {
            type: "static",
            ip: nil,
            netmask: "255.255.255.0",
            adapter: nil,
            mac: nil,
            intnet: nil,
            auto_config: true
          }.merge(options || {})
        end

        def intnet_adapter(config)
          intnet_name = config[:intnet]
          intnet_name = "intnet" if intnet_name == true

          return {
            adapter: config[:adapter],
            type: :intnet,
            mac_address: config[:mac],
            nic_type: config[:nic_type],
            intnet: intnet_name,
          }
        end

        def intnet_network_config(config)
          return {
            type: config[:type],
            ip: config[:ip],
            netmask: config[:netmask]
          }
        end

        def nat_config(options)
          return {
            auto_config: false
          }
        end

        def nat_adapter(config)
          return {
            adapter: config[:adapter],
            type:    :nat,
          }
        end

        def nat_network_config(config)
          return {}
        end

        #-----------------------------------------------------------------
        # Misc. helpers
        #-----------------------------------------------------------------
        # Assigns the actual interface number of a network based on the
        # enabled NICs on the virtual machine.
        #
        # This interface number is used by the guest to configure the
        # NIC on the guest VM.
        #
        # The networks are modified in place by adding an ":interface"
        # field to each.
        def assign_interface_numbers(networks, adapters)
          current = 0
          adapter_to_interface = {}

          # Make a first pass to assign interface numbers by adapter location
          vm_adapters = @env[:machine].provider.driver.read_network_interfaces
          vm_adapters.sort.each do |number, adapter|
            if adapter[:type] != :none
              # Not used, so assign the interface number and increment
              adapter_to_interface[number] = current
              current += 1
            end
          end

          # Make a pass through the adapters to assign the :interface
          # key to each network configuration.
          adapters.each_index do |i|
            adapter = adapters[i]
            network = networks[i]

            # Figure out the interface number by simple lookup
            network[:interface] = adapter_to_interface[adapter[:adapter]]
          end
        end

        #-----------------------------------------------------------------
        # Hostonly Helper Functions
        #-----------------------------------------------------------------
        # This creates a host only network for the given configuration.
        def hostonly_create_network(config)
          @env[:machine].provider.driver.create_host_only_network(
            adapter_ip: config[:adapter_ip],
            netmask:    config[:netmask]
          )
        end

        # This finds a matching host only network for the given configuration.
        def hostonly_find_matching_network(config)
          this_netaddr = network_address(config[:ip], config[:netmask])

          @env[:machine].provider.driver.read_host_only_interfaces.each do |interface|
            return interface if config[:name] && config[:name] == interface[:name]
            return interface if this_netaddr == \
              network_address(interface[:ip], interface[:netmask])
          end

          nil
        end

        #-----------------------------------------------------------------
        # DHCP Server Helper Functions
        #-----------------------------------------------------------------

        DEFAULT_DHCP_SERVER_FROM_VBOX_INSTALL = {
          network_name: 'HostInterfaceNetworking-vboxnet0',
          network:      'vboxnet0',
          ip:           '192.168.56.100',
          netmask:      '255.255.255.0',
          lower:        '192.168.56.101',
          upper:        '192.168.56.254'
        }.freeze

        #
        # When a host-only network of type: :dhcp is configured,
        # this handles the potential creation of a vbox dhcpserver to manage
        # it.
        #
        # @param [Hash<String>] interface hash as returned from read_host_only_interfaces
        # @param [Hash<String>] config hash as returned from hostonly_config
        def create_dhcp_server_if_necessary(interface, config)
          existing_dhcp_server = find_matching_dhcp_server(interface)

          if existing_dhcp_server
            if dhcp_server_matches_config?(existing_dhcp_server, config)
              @logger.debug("DHCP server already properly configured")
              return
            elsif existing_dhcp_server == DEFAULT_DHCP_SERVER_FROM_VBOX_INSTALL
              @env[:ui].info I18n.t("vagrant.actions.vm.network.cleanup_vbox_default_dhcp")
              @env[:machine].provider.driver.remove_dhcp_server(existing_dhcp_server[:network_name])
            else
              # We have an invalid DHCP server that we're not able to
              # automatically clean up, so we need to give up and tell the user
              # to sort out their own vbox dhcpservers and hostonlyifs
              raise Vagrant::Errors::NetworkDHCPAlreadyAttached
            end
          end

          @logger.debug("Creating a DHCP server...")
          @env[:machine].provider.driver.create_dhcp_server(interface[:name], config)
        end

        # Detect when an existing DHCP server matches precisely the
        # requested config for a hostonly interface.
        #
        # @param [Hash<String>] dhcp_server as found by read_dhcp_servers
        # @param [Hash<String>] config as returned from hostonly_config
        # @return [Boolean]
        def dhcp_server_matches_config?(dhcp_server, config)
          dhcp_server[:ip]    == config[:dhcp_ip]    &&
          dhcp_server[:lower] == config[:dhcp_lower] &&
          dhcp_server[:upper] == config[:dhcp_upper]
        end

        # Returns the existing dhcp server, if any, that is attached to the
        # specified interface.
        #
        # @return [Hash<String>] dhcp_server or nil if not found
        def find_matching_dhcp_server(interface)
          @env[:machine].provider.driver.read_dhcp_servers.detect do |dhcp_server|
            interface[:name] && interface[:name] == dhcp_server[:network]
          end
        end
      end
    end
  end
end
