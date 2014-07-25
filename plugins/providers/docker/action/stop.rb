module VagrantPlugins
  module DockerProvider
    module Action
      class Stop
        def initialize(app, _env)
          @app = app
        end

        def call(env)
          machine = env[:machine]
          driver  = machine.provider.driver
          if driver.running?(machine.id)
            env[:ui].info I18n.t('docker_provider.messages.stopping')
            driver.stop(machine.id)
          end
          @app.call(env)
        end
      end
    end
  end
end
