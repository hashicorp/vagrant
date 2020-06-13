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
          #
          # Note: This remap might not be required yet (as it is with the virtualbox provider)
          # so for now we leave the remap hash empty.
          remap = {}
          env[:port_collision_remap] = remap

          # This port checker method calls the custom port_check method
          # defined below. If its false, it will go ahead and use the built-in
          # port_check method to see if there are any live containers with bound
          # ports
          docker_port_check = proc { |host_ip, host_port|
                                      result = port_check(env, host_port)
                                      if !result
                                        result = Vagrant::Action::Builtin::HandleForwardedPortCollisions.port_check(machine, host_ip, host_port)
                                      end
                                      result}
          env[:port_collision_port_check] = docker_port_check

          @app.call(env)
        end

        protected

        # This check is required the docker provider. Containers
        # can bind ports but be halted. We don't want new containers to
        # grab these bound ports, so this check is here for that since
        # the checks above won't detect it
        #
        # @param [Vagrant::Environment] env
        # @param [String] host_port
        # @returns [Bool]
        def port_check(env, host_port)
          extra_in_use = env[:port_collision_extra_in_use]

          if extra_in_use
            return extra_in_use.include?(host_port.to_s)
          else
            return false
          end
        end
      end
    end
  end
end
