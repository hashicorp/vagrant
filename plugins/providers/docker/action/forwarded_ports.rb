module VagrantPlugins
  module DockerProvider
    module Action
      class ForwardedPorts
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:machine].provider_config.ports.each do |p|
            host, guest = p.split(":", 2)
            env[:machine].config.vm.network "forwarded_port",
              host: host.to_i, guest: guest.to_i
          end

          @app.call(env)
        end
      end
    end
  end
end
