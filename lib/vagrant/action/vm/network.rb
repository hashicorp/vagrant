module Vagrant
  module Action
    module VM
      # Networking middleware for Vagrant. This enables host only
      # networking on VMs if configured as such.
      class Network
        def initialize(app, env)
          @app = app
          @env = env

          if enable_network? && Util::Platform.windows? && Util::Platform.bit64?
            raise Errors::NetworkNotImplemented
          end

          env[:vm].config.vm.network_options.compact.each do |network_options|
            raise Errors::NetworkCollision if !verify_no_bridge_collision(network_options)
          end
        end

        def call(env)
          @env = env
          assign_network if enable_network?

          @app.call(env)

          if enable_network?
            @env[:ui].info I18n.t("vagrant.actions.vm.network.enabling")

            # Prepare for new networks...
            options = @env[:vm].config.vm.network_options.compact
            options.each do |network_options|
              @env["vm"].system.prepare_host_only_network(network_options)
            end

            # Then enable the networks...
            options.each do |network_options|
              @env["vm"].system.enable_host_only_network(network_options)
            end
          end
        end

        # Verifies that there is no collision with a bridged network interface
        # for the given network options.
        def verify_no_bridge_collision(net_options)
          interfaces = VirtualBox::Global.global.host.network_interfaces
          interfaces.each do |ni|
            next if ni.interface_type == :host_only

            result = if net_options[:name]
              true if net_options[:name] == ni.name
            else
              true if matching_network?(ni, net_options)
            end

            return false if result
          end

          true
        end

        def enable_network?
          !@env[:vm].config.vm.network_options.compact.empty?
        end

        # Enables and assigns the host only network to the proper
        # adapter on the VM, and saves the adapter.
        def assign_network
          @env[:ui].info I18n.t("vagrant.actions.vm.network.preparing")

          @env[:vm].config.vm.network_options.compact.each do |network_options|
            adapter = @env["vm"].vm.network_adapters[network_options[:adapter]]
            adapter.enabled = true
            adapter.attachment_type = :host_only
            adapter.host_only_interface = network_name(network_options)
            adapter.mac_address = network_options[:mac].gsub(':', '') if network_options[:mac]
            adapter.save
          end
        end

        # Returns the name of the proper host only network, or creates
        # it if it does not exist. Vagrant determines if the host only
        # network exists by comparing the netmask and the IP.
        def network_name(net_options)
          # First try to find a matching network
          interfaces = VirtualBox::Global.global.host.network_interfaces
          interfaces.each do |ni|
            # Ignore non-host only interfaces which may also match,
            # since they're not valid options.
            next if ni.interface_type != :host_only

            if net_options[:name]
              return ni.name if net_options[:name] == ni.name
            else
              return ni.name if matching_network?(ni, net_options)
            end
          end

          raise Errors::NetworkNotFound, :name => net_options[:name] if net_options[:name]

          # One doesn't exist, create it.
          @env[:ui].info I18n.t("vagrant.actions.vm.network.creating")

          ni = interfaces.create
          ni.enable_static(network_ip(net_options[:ip], net_options[:netmask]),
                           net_options[:netmask])
          ni.name
        end

        # Tests if a network matches the given options by applying the
        # netmask to the IP of the network and also to the IP of the
        # virtual machine and see if they match.
        def matching_network?(interface, net_options)
          interface.network_mask == net_options[:netmask] &&
            apply_netmask(interface.ip_address, interface.network_mask) ==
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
