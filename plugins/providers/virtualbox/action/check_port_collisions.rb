require "set"

require "vagrant/util/is_port_open"

module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class CheckPortCollisions
        include Util::CompileForwardedPorts
        include Vagrant::Util::IsPortOpen

        def initialize(app, env)
          @app = app
        end

        def call(env)
          # For the handlers...
          @env = env

          # If we don't have forwarded ports set on the environment, then
          # we compile them.
          env[:forwarded_ports] ||= compile_forwarded_ports(env[:machine].config)

          existing = env[:machine].provider.driver.read_used_ports

          # Calculate the auto-correct port range
          @usable_ports = Set.new(env[:machine].config.vm.usable_port_range)
          @usable_ports.subtract(env[:forwarded_ports].collect { |fp| fp.host_port })
          @usable_ports.subtract(existing)

          # Figure out how we handle port collisions. By default we error.
          handler = env[:port_collision_handler] || :error

          # Read our forwarded ports, if we have any, to override what
          # we have configured.
          current = {}
          env[:machine].provider.driver.read_forwarded_ports.each do |nic, name, hostport, guestport|
            current[name] = hostport.to_i
          end

          env[:forwarded_ports].each do |fp|
            # Use the proper port, whether that be the configured port or the
            # port that is currently on use of the VM.
            host_port = fp.host_port
            host_port = current[fp.id] if current.has_key?(fp.id)

            if existing.include?(host_port) || is_port_open?("127.0.0.1", host_port)
              # We have a collision! Handle it
              send("handle_#{handler}".to_sym, fp, existing)
            end
          end

          @app.call(env)
        end

        # Handles a port collision by raising an exception.
        def handle_error(fp, existing_ports)
          raise Vagrant::Errors::ForwardPortCollisionResume
        end

        # Handles a port collision by attempting to fix it.
        def handle_correct(fp, existing_ports)
          # We need to keep this for messaging purposes
          original_hostport = fp.host_port

          if !fp.auto_correct
            # Auto fixing is disabled for this port forward, so we
            # must throw an error so the user can fix it.
            raise Vagrant::Errors::ForwardPortCollision,
              :host_port => fp.host_port.to_s,
              :guest_port => fp.guest_port.to_s
          end

          if @usable_ports.empty?
            raise Vagrant::Errors::ForwardPortAutolistEmpty,
              :vm_name => @env[:machine].name,
              :host_port => fp.host_port.to_s,
              :guest_port => fp.guest_port.to_s
          end

          # Get the first usable port and set it up
          new_port = @usable_ports.to_a.sort[0]
          @usable_ports.delete(new_port)
          fp.correct_host_port(new_port)
          existing_ports << new_port

          # Notify the user
          @env[:ui].info(I18n.t("vagrant.actions.vm.forward_ports.fixed_collision",
                                :host_port => original_hostport.to_s,
                                :guest_port => fp.guest_port.to_s,
                                :new_port => fp.host_port.to_s))
        end
      end
    end
  end
end
