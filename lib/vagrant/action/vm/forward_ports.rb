module Vagrant
  module Action
    module VM
      class ForwardPorts
        def initialize(app,env)
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
          # Get all the port mappings in the order they're defined and
          # organize them by their guestport, taking the "last one wins"
          # approach.
          guest_port_mapping = {}
          @env[:vm].config.vm.forwarded_ports.each do |options|
            guest_port_mapping[options[:guestport]] = options
          end

          # Return the values, since the order doesn't really matter
          guest_port_mapping.values
        end

        # This method checks for any forwarded ports on the host below
        # 1024, which causes the forwarded ports to fail.
        def threshold_check(ports)
          ports.each do |options|
            if options[:hostport] <= 1024
              @env[:ui].warn I18n.t("vagrant.actions.vm.forward_ports.privileged_ports")
              return
            end
          end
        end

        def forward_ports(mappings)
          ports = []

          interfaces = @env[:vm].driver.read_network_interfaces

          mappings.each do |options|
            message_attributes = {
              :guest_port => options[:guestport],
              :host_port => options[:hostport],
              :adapter => options[:adapter]
            }

            # Assuming the only reason to establish port forwarding is
            # because the VM is using Virtualbox NAT networking. Host-only
            # bridged networking don't require port-forwarding and establishing
            # forwarded ports on these attachment types has uncertain behaviour.
            @env[:ui].info(I18n.t("vagrant.actions.vm.forward_ports.forwarding_entry",
                                    message_attributes))

            # Port forwarding requires the network interface to be a NAT interface,
            # so verify that that is the case.
            if interfaces[options[:adapter]][:type] != :nat
              @env[:ui].info(I18n.t("vagrant.actions.vm.forward_ports.non_nat",
                                    message_attributes))
              next
            end

            # Add the options to the ports array to send to the driver later
            ports << options.merge(:name => options[:name], :adapter => options[:adapter])
          end

          if !ports.empty?
            # We only need to forward ports if there are any to forward
            @env[:vm].driver.forward_ports(ports)
          end
        end
      end
    end
  end
end
