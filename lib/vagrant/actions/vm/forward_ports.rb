module Vagrant
  module Actions
    module VM
      class ForwardPorts < Base
        def prepare
          external_collision_check
        end

        # This method checks for any port collisions with any VMs
        # which are already created (by Vagrant or otherwise).
        # report the collisions detected or will attempt to fix them
        # automatically if the port is configured to do so.
        def external_collision_check
          # Flatten all the already-created forwarded ports into a
          # flat list.
          used_ports = VirtualBox::VM.all.collect do |vm|
            if vm.running? && vm.uuid != runner.uuid
              vm.forwarded_ports.collect do |fp|
                fp.hostport.to_s
              end
            end
          end

          used_ports.flatten!
          used_ports.uniq!

          runner.env.config.vm.forwarded_ports.each do |name, options|
            if used_ports.include?(options[:hostport].to_s)
              handle_collision(name, options, used_ports)
            end
          end
        end

        # Handles any collisions. This method will either attempt to
        # fix the collision automatically or will raise an error if
        # auto fixing is disabled.
        def handle_collision(name, options, used_ports)
          if !options[:auto]
            # Auto fixing is disabled for this port forward, so we
            # must throw an error so the user can fix it.
            raise ActionException.new(:vm_port_collision, :name => name, :hostport => options[:hostport].to_s, :guestport => options[:guestport].to_s, :adapter => options[:adapter])
          end

          # Get the auto port range and get rid of the used ports and
          # ports which are being used in other forwards so we're just
          # left with available ports.
          range = runner.env.config.vm.auto_port_range.to_a
          range -= runner.env.config.vm.forwarded_ports.collect { |n, o| o[:hostport].to_i }
          range -= used_ports

          if range.empty?
            raise ActionException.new(:vm_port_auto_empty, :vm_name => @runner.name, :name => name, :options => options)
          end

          # Set the port up to be the first one and add that port to
          # the used list.
          options[:hostport] = range.shift
          used_ports << options[:hostport]

          # Notify the user
          logger.info "Fixed port collision: #{name} now on port #{options[:hostport]}"
        end

        def execute!
          clear
          forward_ports
        end

        def clear
          logger.info "Deleting any previously set forwarded ports..."
          @runner.vm.forwarded_ports.collect { |p| p.destroy }
        end

        def forward_ports
          logger.info "Forwarding ports..."

          @runner.env.config.vm.forwarded_ports.each do |name, options|
            adapter = options[:adapter]

            # Assuming the only reason to establish port forwarding is because the VM is using Virtualbox NAT networking.
            # Host-only or Bridged networking don't require port-forwarding and establishing forwarded ports on these
            # attachment types has uncertain behaviour.
            if @runner.vm.network_adapters[adapter].attachment_type == :nat
               logger.info "Forwarding \"#{name}\": #{options[:guestport]} on adapter \##{adapter+1} => #{options[:hostport]}"
               port = VirtualBox::ForwardedPort.new
               port.name = name
               port.hostport = options[:hostport]
               port.guestport = options[:guestport]
               port.instance = adapter
               @runner.vm.forwarded_ports << port
            else
              logger.info "VirtualBox adapter \##{adapter+1} not configured as \"NAT\"."
              logger.info "Skipped port forwarding \"#{name}\": #{options[:guestport]} on adapter\##{adapter+1} => #{options[:hostport]}"
            end
          end

          @runner.vm.save
        end
      end
    end
  end
end
