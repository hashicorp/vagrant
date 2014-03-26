module VagrantPlugins
  module DockerProvider
    module Action
      class Created
        def initialize(app, env)
          @app = app
        end

        def call(env)
          machine      = env[:machine]
          driver       = machine.provider.driver
          env[:result] = machine.id && driver.created?(machine.id)
          @app.call(env)
        end
      end
    end
  end
end
