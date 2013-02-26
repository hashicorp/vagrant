require "set"

require "log4r"

require "vagrant/util/is_port_open"

module Vagrant
  module Action
    module Builtin
      # This middleware class will detect and handle collisions with
      # forwarded ports, whether that means raising an error or repairing
      # them automatically.
      #
      # Parameters it takes from the environment hash:
      #
      #   * `:port_collision_repair` - If true, it will attempt to repair
      #     port collisions. If false, it will raise an exception when
      #     there is a collision.
      #
      class HandleForwardedPortCollisions
        include Util::IsPortOpen

        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::action::builtin::handle_port_collisions")
        end

        def call(env)
          @logger.debug("Detecting any forwarded port collisions...")

          # Determine the handler we'll use if we have any port collisions
          repair = !!env[:port_collision_repair]

          # Determine a list of usable ports for repair
          usable_ports = Set.new(env[:machine].config.vm.usable_port_range)

          # Pass one, remove all defined host ports from usable ports
          with_forwarded_ports do |args|
            usable_ports.delete(args[1])
          end

          # Pass two, detect/handle any collisions
          with_forwarded_ports do |args|
            # Get the host port of this forwarded port
            # TODO: handle overrides in the case that an existing VM is
            # already running with auto-corrected ports.
            guest_port = args[0]
            host_port  = args[1]

            # If the port is open (listening for TCP connections)
            if is_port_open?("127.0.0.1", host_port)
              if !repair
                raise Errors::ForwardPortCollision,
                  :guest_port => guest_port.to_s,
                  :host_port  => host_port.to_s
              end

              @logger.info("Attempting to repair FP collision: #{host_port}")

              # If we have no usable ports then we can't repair
              if usable_ports.empty?
                raise Errors::ForwardPortAutolistEmpty,
                  :vm_name    => env[:machine].name,
                  :guest_port => guest_port.to_s,
                  :host_port  => host_port.to_s
              end

              # Attempt to repair the forwarded port
              repaired_port = usable_ports.to_a.sort[0]
              usable_ports.delete(repaired_port)

              # Modify the args in place
              args[1] = repaired_port

              @logger.info("Repaired FP collision: #{host_port} to #{repaired_port}")
            end
          end
        end

        protected

        def with_forwarded_ports
          env[:machine].config.vm.networks.each do |type, args|
            # Ignore anything but forwarded ports
            next if type != :forwarded_port

            yield args
          end
        end
      end
    end
  end
end
