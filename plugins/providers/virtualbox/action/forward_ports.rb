module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class ForwardPorts
        def initialize(app, env)
          @app = app
        end

        #--------------------------------------------------------------
        # Execution
        #--------------------------------------------------------------
        def call(env)
          @env = env

          # Get the ports we're forwarding
          ports = forward_port_definitions

          # Warn if we're port forwarding to any privileged ports...
          threshold_check(ports)

          env[:ui].info I18n.t("vagrant.actions.vm.forward_ports.forwarding")
          forward_ports(ports)

          @app.call(env)
        end

        # This returns an array of forwarded ports with overrides properly
        # squashed.
        def forward_port_definitions
          # Get all of the forwarded port definitions in the network and
          # convert it to a forwarded port model for use in the rest of
          # the action.
          #
          # Duplicate forward port definitions are treated as "last one wins"
          # where the last host port definition wins.
          fp_mapping = {}
          @env[:machine].config.vm.networks.each do |type, args|
            # We only care about forwarded ports currently
            if type == :forwarded_port
              options    = args[2] || {}
              host_port  = args[0].to_i
              guest_port = args[1].to_i
              id         = options[:id] || "#{guest_port.to_s(32)}-#{host_port.to_s(32)}"

              fp_mapping[host_port] =
                Model::ForwardedPort.new(id, host_port, guest_port, options)
            end
          end

          # Return the values, since the order doesn't really matter
          fp_mapping.values
        end

        # This method checks for any forwarded ports on the host below
        # 1024, which causes the forwarded ports to fail.
        def threshold_check(ports)
          ports.each do |port|
            if port.host_port <= 1024
              @env[:ui].warn I18n.t("vagrant.actions.vm.forward_ports.privileged_ports")
              return
            end
          end
        end

        def forward_ports(mappings)
          ports = []

          interfaces = @env[:machine].provider.driver.read_network_interfaces

          mappings.each do |port|
            message_attributes = {
              :guest_port => port.guest_port,
              :host_port => port.host_port,
              :adapter => port.adapter
            }

            # Assuming the only reason to establish port forwarding is
            # because the VM is using Virtualbox NAT networking. Host-only
            # bridged networking don't require port-forwarding and establishing
            # forwarded ports on these attachment types has uncertain behaviour.
            @env[:ui].info(I18n.t("vagrant.actions.vm.forward_ports.forwarding_entry",
                                    message_attributes))

            # Port forwarding requires the network interface to be a NAT interface,
            # so verify that that is the case.
            if interfaces[port.adapter][:type] != :nat
              @env[:ui].info(I18n.t("vagrant.actions.vm.forward_ports.non_nat",
                                    message_attributes))
              next
            end

            # Add the options to the ports array to send to the driver later
            ports << {
              :adapter   => port.adapter,
              :guestport => port.guest_port,
              :hostport  => port.host_port,
              :name      => port.id,
              :protocol  => port.protocol
            }
          end

          if !ports.empty?
            # We only need to forward ports if there are any to forward
            @env[:machine].provider.driver.forward_ports(ports)
          end
        end
      end
    end
  end
end
