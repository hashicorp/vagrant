module VagrantPlugins
  module DockerProvider
    module Action
      class PrepareForwardedPortCollisionParams
        def initialize(app, env)
          @app = app
        end

        def call(env)
          machine = env[:machine]

          # Get the forwarded ports used by other containers and
          # consider those in use as well.
          other_used_ports = machine.provider.driver.read_used_ports
          env[:port_collision_extra_in_use] = other_used_ports

          # Build the remap for any existing collision detections
          remap = {}
          env[:port_collision_remap] = remap

          # Note: This might not be required yet (as it is with the virtualbox provider)
          # so for now we leave the remap hash empty.

          @app.call(env)
        end
      end
    end
  end
end
