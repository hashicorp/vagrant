require "set"

require "log4r"

require "vagrant/util/network_ip"

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
          available_slots = Set.new(1..8)
          network_adapters_config.each do |slot, _data|
            available_slots.delete(slot)
          end

          @logger.debug("Available slots for high-level adapters: #{available_slots.inspect}")
          @logger.info("Determinging network adapters required for high-level configuration...")
          available_slots = available_slots.to_a.sort
          env[:machine].config.vm.networks.each do |type, args|
            # We only handle private and public networks
            next if type != :private_network && type != :public_network

            options = nil
            options = args.last if args.last.is_a?(Hash)
            options ||= {}

            # Figure out the slot that this adapter will go into
            slot = options[:virtualbox__adapter]
            if !slot
              if available_slots.empty?
                # TODO: Error that we have no room for this adapter
              end

              slot = available_slots.shift
            end

            # Configure it
            data = nil
            if type == :private_network
              # private_network = hostonly

              config_args = [args[0]]
              data = [:hostonly, config_args]
            elsif type == :public_network
              # public_network = bridged

              config_args = []
              data = [:bridged, config_args]
            end

            # Store it!
            @logger.info(" -- Slot #{slot}: #{data[0]}")
            network_adapters_config[slot] = data
          end

          @logger.info("Determining adapters and compiling network configuration...")
          adapters = []
          network_adapters_config.each do |slot, data|
            type = data[0]
            args = data[1]

            @logger.info("Network slot #{slot}. Type: #{type}.")

            # Get the normalized configuration for this type
            config = send("#{type}_config", args)
            config[:adapter] = slot

            @logger.debug("Normalized configuration: #{config.inspect}")

            # Get the VirtualBox adapter configuration
            adapter = send("#{type}_adapter", config)
            adapters << adapter

            @logger.debug("Adapter configuration: #{adapter.inspect}")
          end

          if !adapters.empty?
            # Enable the adapters
            @logger.info("Enabling adapters...")
            env[:ui].info I18n.t("vagrant.actions.vm.network.preparing")
            env[:machine].provider.driver.enable_adapters(adapters)
          end

          # Continue the middleware chain.
          @app.call(env)

          # TODO: Configure running-VM networks
        end

        def hostonly_config(args)
          ip      = args[0]
          options = {
            :netmask => "255.255.255.0"
          }.merge(args[1] || {})

          # Calculate our network address for the given IP/netmask
          netaddr  = network_address(ip, options[:netmask])

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

          return {
            :adapter_ip => adapter_ip,
            :ip         => ip,
            :netmask    => options[:netmask],
            :type       => :static
          }
        end

        def hostonly_adapter(config)
          @logger.info("Searching for matching hostonly network: #{config[:ip]}")
          interface = hostonly_find_matching_network(config)

          if !interface
            @logger.info("Network not found. Creating if we can.")

            # It is an error if a specific host only network name was specified
            # but the network wasn't found.
            if config[:name]
              raise Vagrant::Errors::NetworkNotFound, :name => config[:name]
            end

            # Create a new network
            interface = hostonly_create_network(config)
            @logger.info("Created network: #{interface[:name]}")
          end

          return {
            :adapter  => config[:adapter],
            :type     => :hostonly,
            :hostonly => interface[:name]
          }
        end

        def nat_config(options)
          return {}
        end

        def nat_adapter(config)
          return {
            :adapter => config[:adapter],
            :type    => :nat,
          }
        end

        #-----------------------------------------------------------------
        # Hostonly Helper Functions
        #-----------------------------------------------------------------
        # This creates a host only network for the given configuration.
        def hostonly_create_network(config)
          @env[:machine].provider.driver.create_host_only_network(
            :adapter_ip => config[:adapter_ip],
            :netmask    => config[:netmask]
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
      end
    end
  end
end
