module Vagrant
  module Actions
    module VM
      class Network < Base
        def before_boot
          assign_network if enable_network?
        end

        def after_boot

        end

        def enable_network?
          !runner.env.config.vm.network_options.nil?
        end

        # Enables and assigns the host only network to the proper
        # adapter on the VM, and saves the adapter.
        def assign_network
          logger.info "Enabling host only network..."

          options = runner.env.config.vm.network_options
          adapter = runner.vm.network_adapters[options[:adapter]]
          adapter.enabled = true
          adapter.attachment_type = :host_only
          adapter.host_interface = network_name(options)
          adapter.save
        end

        # Returns the name of the proper host only network, or creates
        # it if it does not exist. Vagrant determines if the host only
        # network exists by comparing the netmask and the IP.
        def network_name(options)
          # First try to find a matching network
          interfaces = VirtualBox::Global.global.host.network_interfaces
          interfaces.each do |ni|
            return ni.name if matching_network?(ni, options)
          end

          # One doesn't exist, create it.
          logger.info "Creating new host only network for environment..."

          ni = interfaces.create
          ni.enable_static(network_ip(options[:ip], options[:netmask]),
                           options[:netmask])
          ni.name
        end

        # Tests if a network matches the given options by applying the
        # netmask to the IP of the network and also to the IP of the
        # virtual machine and see if they match.
        def matching_network?(interface, options)
          interface.network_mask == options[:netmask] &&
            apply_netmask(interface.ip_address, interface.network_mask) ==
            apply_netmask(options[:ip], options[:netmask])
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
