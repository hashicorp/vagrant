module VagrantPlugins
  module DockerProvider
    module Action
      class IsRunning
        def initialize(app, env)
          @app = app
        end

        def call(env)
          machine    = env[:machine]
          driver     = machine.provider.driver

          env[:result] = driver.running?(machine.id)

          @app.call(env)
        end
      end
    end
  end
end
