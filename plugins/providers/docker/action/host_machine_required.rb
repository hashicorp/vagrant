module VagrantPlugins
  module DockerProvider
    module Action
      # This middleware is used with Call to test if we're using a host VM.
      class HostMachineRequired
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:result] = env[:machine].provider.host_vm?
          @app.call(env)
        end
      end
    end
  end
end
