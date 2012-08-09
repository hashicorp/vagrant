require "vagrant/util/is_port_open"

module Vagrant
  module Action
    module VM
      # Action that checks to make sure there are no forwarded port collisions,
      # and raises an exception if there is.
      class CheckPortCollisions
        include Util::IsPortOpen

        def initialize(app, env)
          @app = app
        end

        def call(env)
          # For the handlers...
          @env = env

          # Figure out how we handle port collisions. By default we error.
          handler  = env[:port_collision_handler] || :error

          # Read our forwarded ports, if we have any, to override what
          # we have configured.
          current = {}
          env[:vm].driver.read_forwarded_ports.each do |nic, name, hostport, guestport|
            current[name] = hostport.to_i
          end

          existing = env[:vm].driver.read_used_ports
          env[:vm].config.vm.forwarded_ports.each do |options|
            # Use the proper port, whether that be the configured port or the
            # port that is currently on use of the VM.
            hostport = options[:hostport].to_i
            hostport = current[options[:name]] if current.has_key?(options[:name])

            if existing.include?(hostport) || is_port_open?("127.0.0.1", hostport)
              # We have a collision! Handle it
              send("handle_#{handler}".to_sym, options, existing)
            end
          end

          @app.call(env)
        end

        # Handles a port collision by raising an exception.
        def handle_error(options, existing_ports)
          raise Errors::ForwardPortCollisionResume
        end

        # Handles a port collision by attempting to fix it.
        def handle_correct(options, existing_ports)
          # We need to keep this for messaging purposes
          original_hostport = options[:hostport]

          if !options[:auto]
            # Auto fixing is disabled for this port forward, so we
            # must throw an error so the user can fix it.
            raise Errors::ForwardPortCollision, :host_port => options[:hostport].to_s,
                                                :guest_port => options[:guestport].to_s
          end

          # Get the auto port range and get rid of the used ports and
          # ports which are being used in other forwards so we're just
          # left with available ports.
          range = @env[:vm].config.vm.auto_port_range.to_a
          range -= @env[:vm].config.vm.forwarded_ports.collect { |opts| opts[:hostport].to_i }
          range -= existing_ports

          if range.empty?
            raise Errors::ForwardPortAutolistEmpty, :vm_name => @env[:vm].name,
                                                    :host_port => options[:hostport].to_s,
                                                    :guest_port => options[:guestport].to_s
          end

          # Set the port up to be the first one and add that port to
          # the used list.
          options[:hostport] = range.shift
          existing_ports << options[:hostport]

          # Notify the user
          @env[:ui].info(I18n.t("vagrant.actions.vm.forward_ports.fixed_collision",
                                :host_port => original_hostport.to_s,
                                :guest_port => options[:guestport].to_s,
                                :new_port => options[:hostport]))
        end
      end
    end
  end
end
