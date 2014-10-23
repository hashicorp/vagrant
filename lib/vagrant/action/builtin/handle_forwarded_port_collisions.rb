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
      #   * `:port_collision_extra_in_use` - An array of ports that are
      #     considered in use.
      #
      #   * `:port_collision_remap` - A hash remapping certain host ports
      #     to other host ports.
      #
      class HandleForwardedPortCollisions
        include Util::IsPortOpen

        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::action::builtin::handle_port_collisions")
        end

        def call(env)
          @leased  = []
          @machine = env[:machine]

          # Acquire a process-level lock so that we don't choose a port
          # that someone else also chose.
          begin
            env[:machine].env.lock("fpcollision") do
              handle(env)
            end
          rescue Errors::EnvironmentLockedError
            sleep 1
            retry
          end

          @app.call(env)

          # Always run the recover method so that we release leases
          recover(env)
        end

        def recover(env)
          lease_release
        end

        protected

        def handle(env)
          @logger.info("Detecting any forwarded port collisions...")

          # Get the extra ports we consider in use
          extra_in_use = env[:port_collision_extra_in_use] || []

          # Get the remap
          remap = env[:port_collision_remap] || {}

          # Determine the handler we'll use if we have any port collisions
          repair = !!env[:port_collision_repair]

          # The method we'll use to check if a port is open.
          port_checker = env[:port_collision_port_check]
          port_checker ||= method(:port_check)

          # Log out some of our parameters
          @logger.debug("Extra in use: #{extra_in_use.inspect}")
          @logger.debug("Remap: #{remap.inspect}")
          @logger.debug("Repair: #{repair.inspect}")

          # Determine a list of usable ports for repair
          usable_ports = Set.new(env[:machine].config.vm.usable_port_range)
          usable_ports.subtract(extra_in_use)

          # Pass one, remove all defined host ports from usable ports
          with_forwarded_ports(env) do |options|
            usable_ports.delete(options[:host])
          end

          # Pass two, detect/handle any collisions
          with_forwarded_ports(env) do |options|
            guest_port = options[:guest]
            host_port  = options[:host]

            if options[:protocol] && options[:protocol] != "tcp"
              @logger.debug("Skipping #{host_port} because UDP protocol.")
              next
            end

            if remap[host_port]
              remap_port = remap[host_port]
              @logger.debug("Remap port override: #{host_port} => #{remap_port}")
              host_port = remap_port
            end

            # If the port is open (listening for TCP connections)
            in_use = extra_in_use.include?(host_port) ||
              port_checker[host_port] ||
              lease_check(host_port)
            if in_use
              if !repair || !options[:auto_correct]
                raise Errors::ForwardPortCollision,
                  guest_port: guest_port.to_s,
                  host_port:  host_port.to_s
              end

              @logger.info("Attempting to repair FP collision: #{host_port}")

              repaired_port = nil
              while !usable_ports.empty?
                # Attempt to repair the forwarded port
                repaired_port = usable_ports.to_a.sort[0]
                usable_ports.delete(repaired_port)

                # If the port is in use, then we can't use this either...
                in_use = extra_in_use.include?(repaired_port) ||
                  port_checker[repaired_port] ||
                  lease_check(repaired_port)
                if in_use
                  @logger.info("Reparied port also in use: #{repaired_port}. Trying another...")
                  next
                end

                # We have a port so break out
                break
              end

              # If we have no usable ports then we can't repair
              if !repaired_port && usable_ports.empty?
                raise Errors::ForwardPortAutolistEmpty,
                  vm_name:    env[:machine].name,
                  guest_port: guest_port.to_s,
                  host_port:  host_port.to_s
              end

              # Modify the args in place
              options[:host] = repaired_port

              @logger.info("Repaired FP collision: #{host_port} to #{repaired_port}")

              # Notify the user
              env[:ui].info(I18n.t("vagrant.actions.vm.forward_ports.fixed_collision",
                                   host_port:  host_port.to_s,
                                   guest_port: guest_port.to_s,
                                   new_port:   repaired_port.to_s))
            end
          end

          @app.call(env)
        end

        def lease_check(port)
          # Check if this port is "leased". We use a leasing system of
          # about 60 seconds to avoid any forwarded port collisions in
          # a highly parallelized environment.
          leasedir = @machine.env.data_dir.join("fp-leases")
          leasedir.mkpath

          invalid = false
          oldest  = Time.now.to_i - 60
          leasedir.children.each do |child|
            # Delete old, invalid leases while we're looking
            if child.file? && child.mtime.to_i < oldest
              child.delete
            end

            if child.basename.to_s == port.to_s
              invalid = true
            end
          end

          # If its invalid, then the port is "open" and in use
          return true if invalid

          # Otherwise, create the lease
          leasedir.join(port.to_s).open("w+") do |f|
            f.binmode
            f.write(Time.now.to_i.to_s + "\n")
          end

          # Add to the leased array so we unlease it right away
          @leased << port.to_s

          # Things look good to us!
          false
        end

        def lease_release
          leasedir = @machine.env.data_dir.join("fp-leases")

          @leased.each do |port|
            path = leasedir.join(port)
            path.delete if path.file?
          end
        end

        def port_check(port)
          is_port_open?("127.0.0.1", port)
        end

        def with_forwarded_ports(env)
          env[:machine].config.vm.networks.each do |type, options|
            # Ignore anything but forwarded ports
            next if type != :forwarded_port

            yield options
          end
        end
      end
    end
  end
end
