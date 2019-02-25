module VagrantPlugins
  module DockerProvider
    module Action
      class Network
        def initialize(app, env)
          @app = app
        end

        def call(env)
          # If we aren't using a host VM, then don't worry about it
          return @app.call(env) if !env[:machine].provider.host_vm?

          @app.call(env)
        end
      end
    end
  end
end
