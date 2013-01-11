module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class ForwardPorts
        include Util::CompileForwardedPorts

        def initialize(app, env)
          @app = app
        end

        #--------------------------------------------------------------
        # Execution
        #--------------------------------------------------------------
        def call(env)
          @env = env

          # Get the ports we're forwarding
          env[:forwarded_ports] ||= compile_forwarded_ports(env[:machine].config)

          # Warn if we're port forwarding to any privileged ports...
          env[:forwarded_ports].each do |fp|
            if fp.host_port <= 1024
              env[:ui].warn I18n.t("vagrant.actions.vm.forward_ports.privileged_ports")
              return
            end
          end

          env[:ui].info I18n.t("vagrant.actions.vm.forward_ports.forwarding")
          forward_ports

          @app.call(env)
        end

        def forward_ports
          ports = []

          interfaces = @env[:machine].provider.driver.read_network_interfaces

          @env[:forwarded_ports].each do |fp|
            message_attributes = {
              :adapter => fp.adapter,
              :guest_port => fp.guest_port,
              :host_port => fp.host_port
            }

            # Assuming the only reason to establish port forwarding is
            # because the VM is using Virtualbox NAT networking. Host-only
            # bridged networking don't require port-forwarding and establishing
            # forwarded ports on these attachment types has uncertain behaviour.
            @env[:ui].info(I18n.t("vagrant.actions.vm.forward_ports.forwarding_entry",
                                    message_attributes))

            # Port forwarding requires the network interface to be a NAT interface,
            # so verify that that is the case.
            if interfaces[fp.adapter][:type] != :nat
              @env[:ui].info(I18n.t("vagrant.actions.vm.forward_ports.non_nat",
                                    message_attributes))
              next
            end

            # Add the options to the ports array to send to the driver later
            ports << {
              :adapter   => fp.adapter,
              :guestport => fp.guest_port,
              :hostport  => fp.host_port,
              :name      => fp.id,
              :protocol  => fp.protocol
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
