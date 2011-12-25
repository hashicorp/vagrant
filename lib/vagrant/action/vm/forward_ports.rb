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

          # Warn if we're port forwarding to any privileged ports...
          threshold_check

          env[:ui].info I18n.t("vagrant.actions.vm.forward_ports.forwarding")
          forward_ports(env[:vm])

          @app.call(env)
        end

        # This method checks for any forwarded ports on the host below
        # 1024, which causes the forwarded ports to fail.
        def threshold_check
          @env[:vm].config.vm.forwarded_ports.each do |name, options|
            if options[:hostport] <= 1024
              @env[:ui].warn I18n.t("vagrant.actions.vm.forward_ports.privileged_ports")
              return
            end
          end
        end

        def forward_ports(vm)
          ports = []

          interfaces = @env[:vm].driver.read_network_interfaces

          @env[:vm].config.vm.forwarded_ports.each do |name, options|
            adapter = options[:adapter] + 1
            message_attributes = {
              :name => name,
              :guest_port => options[:guestport],
              :host_port => options[:hostport],
              :adapter => adapter
            }

            # Assuming the only reason to establish port forwarding is
            # because the VM is using Virtualbox NAT networking. Host-only
            # bridged networking don't require port-forwarding and establishing
            # forwarded ports on these attachment types has uncertain behaviour.
            @env[:ui].info(I18n.t("vagrant.actions.vm.forward_ports.forwarding_entry",
                                    message_attributes))

            # Port forwarding requires the network interface to be a NAT interface,
            # so verify that that is the case.
            if interfaces[adapter][:type] != "nat"
              @env[:ui].info(I18n.t("vagrant.actions.vm.forward_ports.non_nat",
                                    message_attributes))
              next
            end

            # Add the options to the ports array to send to the driver later
            ports << options.merge(:name => name, :adapter => adapter)
          end

          @env[:vm].driver.forward_ports(ports)
        end
      end
    end
  end
end
