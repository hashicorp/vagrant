module VagrantPlugins
  module HyperV
    module Action
      class StopInstance
        def initialize(app, _env)
          @app    = app
        end

        def call(env)
          env[:ui].info('Stopping the machine...')
          env[:machine].provider.driver.stop
          @app.call(env)
        end
      end
    end
  end
end
