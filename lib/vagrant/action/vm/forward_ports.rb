require File.join(File.dirname(__FILE__), 'forward_ports_helpers')

module Vagrant
  class Action
    module VM
      class ForwardPorts
        include ForwardPortsHelpers

        def initialize(app,env)
          @app = app
          @env = env

          threshold_check
          external_collision_check if !env.error?
        end

        #--------------------------------------------------------------
        # Prepare Helpers - These functions are not involved in actually
        # executing the action
        #--------------------------------------------------------------

        # This method checks for any forwarded ports on the host below
        # 1024, which causes the forwarded ports to fail.
        def threshold_check
          @env.env.config.vm.forwarded_ports.each do |name, options|
            return @env.error!(:vm_port_below_threshold) if options[:hostport] <= 1024
          end
        end

        # This method checks for any port collisions with any VMs
        # which are already created (by Vagrant or otherwise).
        # report the collisions detected or will attempt to fix them
        # automatically if the port is configured to do so.
        def external_collision_check
          existing = used_ports
          @env.env.config.vm.forwarded_ports.each do |name, options|
            if existing.include?(options[:hostport].to_s)
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
            return @env.error!(:vm_port_collision, :name => name, :hostport => options[:hostport].to_s, :guestport => options[:guestport].to_s, :adapter => options[:adapter])
          end

          # Get the auto port range and get rid of the used ports and
          # ports which are being used in other forwards so we're just
          # left with available ports.
          range = @env.env.config.vm.auto_port_range.to_a
          range -= @env.env.config.vm.forwarded_ports.collect { |n, o| o[:hostport].to_i }
          range -= existing_ports

          if range.empty?
            return @env.error!(:vm_port_auto_empty, :vm_name => @env["vm"].name, :name => name, :options => options)
          end

          # Set the port up to be the first one and add that port to
          # the used list.
          options[:hostport] = range.shift
          existing_ports << options[:hostport]

          # Notify the user
          @env.logger.info "Fixed port collision: #{name} now on port #{options[:hostport]}"
        end

        #--------------------------------------------------------------
        # Execution
        #--------------------------------------------------------------
        def call(env)
          @env = env

          forward_ports

          @app.call(env)
        end

        def forward_ports
          @env.logger.info "Forwarding ports..."

          @env.env.config.vm.forwarded_ports.each do |name, options|
            adapter = options[:adapter]

            # Assuming the only reason to establish port forwarding is because the VM is using Virtualbox NAT networking.
            # Host-only or Bridged networking don't require port-forwarding and establishing forwarded ports on these
            # attachment types has uncertain behaviour.
            if @env["vm"].vm.network_adapters[adapter].attachment_type == :nat
              @env.logger.info "Forwarding \"#{name}\": #{options[:guestport]} on adapter \##{adapter+1} => #{options[:hostport]}"
              forward_port(name, options)
            else
              @env.logger.info "VirtualBox adapter \##{adapter+1} not configured as \"NAT\"."
              @env.logger.info "Skipped port forwarding \"#{name}\": #{options[:guestport]} on adapter\##{adapter+1} => #{options[:hostport]}"
            end
          end

          @env["vm"].vm.save
          @env["vm"].reload!
        end

        #--------------------------------------------------------------
        # General Helpers
        #--------------------------------------------------------------

        # Forwards a port.
        def forward_port(name, options)
          port = VirtualBox::NATForwardedPort.new
          port.name = name
          port.guestport = options[:guestport]
          port.hostport = options[:hostport]
          @env["vm"].vm.network_adapters[options[:adapter]].nat_driver.forwarded_ports << port
        end
      end
    end
  end
end
