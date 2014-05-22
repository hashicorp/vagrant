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
              break
            end
          end

          env[:ui].output(I18n.t("vagrant.actions.vm.forward_ports.forwarding"))
          forward_ports

          @app.call(env)
        end

        def forward_ports
          ports = []

          interfaces = @env[:machine].provider.driver.read_network_interfaces

          @env[:forwarded_ports].each do |fp|
            message_attributes = {
              adapter: fp.adapter,
              guest_port: fp.guest_port,
              host_port: fp.host_port
            }

            # Assuming the only reason to establish port forwarding is
            # because the VM is using Virtualbox NAT networking. Host-only
            # bridged networking don't require port-forwarding and establishing
            # forwarded ports on these attachment types has uncertain behaviour.
            @env[:ui].detail(I18n.t("vagrant.actions.vm.forward_ports.forwarding_entry",
                                    message_attributes))

            # Verify we have the network interface to attach to
            if !interfaces[fp.adapter]
              raise Vagrant::Errors::ForwardPortAdapterNotFound,
                adapter: fp.adapter.to_s,
                guest: fp.guest_port.to_s,
                host: fp.host_port.to_s
            end

            # Port forwarding requires the network interface to be a NAT interface,
            # so verify that that is the case.
            if interfaces[fp.adapter][:type] != :nat
              @env[:ui].detail(I18n.t("vagrant.actions.vm.forward_ports.non_nat",
                                    message_attributes))
              next
            end

            # Add the options to the ports array to send to the driver later
            ports << {
              adapter:   fp.adapter,
              guestip:   fp.guest_ip,
              guestport: fp.guest_port,
              hostip:    fp.host_ip,
              hostport:  fp.host_port,
              name:      fp.id,
              protocol:  fp.protocol
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
