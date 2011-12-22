module Vagrant
  module Action
    module VM
      class ForwardPorts
        def initialize(app,env)
          @app = app
          @env = env

          threshold_check
          external_collision_check
        end

        #--------------------------------------------------------------
        # Prepare Helpers - These functions are not involved in actually
        # executing the action
        #--------------------------------------------------------------

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

        # This method checks for any port collisions with any VMs
        # which are already created (by Vagrant or otherwise).
        # report the collisions detected or will attempt to fix them
        # automatically if the port is configured to do so.
        def external_collision_check
          existing = @env[:vm].driver.read_used_ports
          @env[:vm].config.vm.forwarded_ports.each do |name, options|
            if existing.include?(options[:hostport].to_i)
              handle_collision(name, options, existing)
            end
          end
        end

        # Handles any collisions. This method will either attempt to
        # fix the collision automatically or will raise an error if
        # auto fixing is disabled.
        def handle_collision(name, options, existing_ports)
          if !options[:auto]
            # Auto fixing is disabled for this port forward, so we
            # must throw an error so the user can fix it.
            raise Errors::ForwardPortCollision, :name => name,
                                                :host_port => options[:hostport].to_s,
                                                :guest_port => options[:guestport].to_s
          end

          # Get the auto port range and get rid of the used ports and
          # ports which are being used in other forwards so we're just
          # left with available ports.
          range = @env[:vm].config.vm.auto_port_range.to_a
          range -= @env[:vm].config.vm.forwarded_ports.collect { |n, o| o[:hostport].to_i }
          range -= existing_ports

          if range.empty?
            raise Errors::ForwardPortAutolistEmpty, :vm_name => @env[:vm].name,
                                                    :name => name,
                                                    :host_port => options[:hostport].to_s,
                                                    :guest_port => options[:guestport].to_s
          end

          # Set the port up to be the first one and add that port to
          # the used list.
          options[:hostport] = range.shift
          existing_ports << options[:hostport]

          # Notify the user
          @env[:ui].info(I18n.t("vagrant.actions.vm.forward_ports.fixed_collision",
                                :name => name,
                                :new_port => options[:hostport]))
        end

        #--------------------------------------------------------------
        # Execution
        #--------------------------------------------------------------
        def call(env)
          @env = env

          env[:ui].info I18n.t("vagrant.actions.vm.forward_ports.forwarding")
          forward_ports(env[:vm])

          @app.call(env)
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
