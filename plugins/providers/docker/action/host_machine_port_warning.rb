module VagrantPlugins
  module DockerProvider
    module Action
      class HostMachinePortWarning
        def initialize(app, env)
          @app = app
        end

        def call(env)
          if !env[:machine].provider.host_vm?
            return @app.call(env)
          end

          # If we have forwarded ports, then notify the user that they
          # won't be immediately available unless a private network
          # is created.
          if has_forwarded_ports?(env[:machine])
            env[:machine].ui.warn(I18n.t(
              "docker_provider.host_machine_forwarded_ports"))
          end

          @app.call(env)
        end

        protected

        def has_forwarded_ports?(machine)
          machine.config.vm.networks.each do |type, _|
            return true if type == :forwarded_port
          end

          false
        end
      end
    end
  end
end
