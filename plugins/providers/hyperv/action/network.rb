require "set"

require "log4r"

require "vagrant/util/network_ip"
require "vagrant/util/scoped_hash_override"

module VagrantPlugins
  module HyperV
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
          @logger = Log4r::Logger.new("vagrant::plugins::hyperv::network")
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
          @logger.info("Determining network adapters required for high-level configuration...")
          available_slots = available_slots.to_a.sort
          env[:machine].config.vm.networks.each do |type, options|
            # We only handle private and public networks
            options = scoped_hash_override(options, :hyperv)

            # Figure out the slot that this adapter will go into
            slot = options[:adapter]
            if !slot
              if available_slots.empty?
                raise Vagrant::Errors::VirtualBoxNoRoomForHighLevelNetwork
              end

              slot = available_slots.shift
            end

            # Configure it
            data = nil
            if type == :private_network
              # private_network = hostonly
              data = [:private, options]
            elsif type == :public_network
              # public_network = bridged
              data = [:external, options]
            elsif type == :forwarded_port
              # public_network = bridged
              data = [:external, options]
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

            # Get the HyperV adapter configuration
            adapter = send("#{type}_adapter", config)
            adapters << adapter
            @logger.debug("Adapter configuration: #{adapter.inspect}")

            # Get the network configuration
            network = send("#{type}_network_config", config)
            network[:auto_config] = config[:auto_config]
            networks << network
          end

          if !adapters.empty?
            switches = env[:machine].provider.driver.execute("get_switches.ps1", {})
            raise Errors::NoSwitches if switches.empty?

            adapters.each do |adapter|
              switchToFind = adapter[:intnet].downcase

              if switchToFind
                @logger.info("Looking for switch with name: #{switchToFind}")
                switch = switches.find { |s| s["Name"].downcase == switchToFind.downcase }["Name"]
                if switch
                  @logger.info("Found switch: #{switch}")
                else
                  @logger.info("Unable to find switch: #{switch}")
                  raise Errors::SwitchDoesNotExist,
                    switch: switchToFind
                end
              end
            end

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

        def external_config(options)
          return {
            :auto_config                     => false,
            :bridge                          => nil,
            :mac                             => nil,
            :nic_type                        => nil,
            :use_dhcp_assigned_default_route => false
          }.merge(options || {})
        end

        def external_adapter(config)
          intnet_name = config[:network_name]
          intnet_name = "external" if intnet_name == true

          # Given the choice we can now define the adapter we're using
          return {
            :adapter     => config[:adapter],
            :type        => :bridged,
            :mac_address => config[:mac],
            :nic_type    => config[:nic_type],
            :intnet => intnet_name,
          }
        end

        def external_network_config(config)
          if config[:ip] && (!config[:type] || config[:type] != :dhcp)
            options = {
                :auto_config => false,
                :mac         => config[:mac],
                :netmask     => "255.255.255.0",
                :type        => :static
            }.merge(config)
            options[:type] = options[:type].to_sym
            return options
          end

          return {
            :type => :dhcp,
            :use_dhcp_assigned_default_route => config[:use_dhcp_assigned_default_route]
          }
        end

        def internal_config(options)
          return {
            :auto_config                     => true,
            :bridge                          => nil,
            :mac                             => nil,
            :nic_type                        => nil,
            :use_dhcp_assigned_default_route => false
          }.merge(options || {})
        end

        def internal_adapter(config)
          intnet_name = config[:network_name]
          intnet_name = "internal" if intnet_name == true

          # Given the choice we can now define the adapter we're using
          return {
            :adapter     => config[:adapter],
            :type        => :static,
            :mac_address => config[:mac],
            :nic_type    => config[:nic_type],
            :intnet => intnet_name,
          }
        end

        def internal_network_config(config)
          if config[:ip] && (!config[:type] || config[:type] != :dhcp)
            options = {
                :auto_config => true,
                :mac         => config[:mac],
                :netmask     => "255.255.255.0",
                :type        => :static
            }.merge(config)            
            return options
          end

          return {
            :type => :dhcp,
            :use_dhcp_assigned_default_route => config[:use_dhcp_assigned_default_route]
          }
        end

        def private_config(options)
          return {
            :type => "static",
            :ip => nil,
            :netmask => "255.255.255.0",
            :adapter => nil,
            :mac => nil,
            :intnet => nil,
            :auto_config => true
          }.merge(options || {})
        end

        def private_adapter(config)
          intnet_name = config[:network_name]
          intnet_name = "private" if intnet_name == true

          return {
            :adapter => config[:adapter],
            :type => config[:type].to_sym,
            :mac_address => config[:mac],
            :nic_type => config[:nic_type],
            :intnet => intnet_name,
          }
        end

        def private_network_config(config)
          if config[:ip] && (!config[:type] || config[:type] != :dhcp)
            options = {
                :ip          => config[:ip],
                :netmask     => config[:netmask],
                :mac         => config[:mac],
                :type        => :static
            }.merge(config)
            return options
          end

          return {
            :type => :dhcp,
            :use_dhcp_assigned_default_route => config[:use_dhcp_assigned_default_route]
          }
        end

        def nat_config(options)
          return {
            :auto_config => false
          }
        end

        def nat_adapter(config)
          intnet_name = config[:network_name]
          intnet_name = "nat" if intnet_name == true

          return {
            :adapter => config[:adapter],
            :mac_address => config[:mac],
            :type    => :nat,
            :intnet => intnet_name,
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