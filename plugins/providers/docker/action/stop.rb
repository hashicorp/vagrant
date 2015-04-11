module VagrantPlugins
  module DockerProvider
    module Action
      class Stop
        def initialize(app, env)
          @app = app
        end

        def call(env)
          machine = env[:machine]
          driver  = machine.provider.driver
          if driver.running?(machine.id)
            env[:ui].info I18n.t("docker_provider.messages.stopping")
            driver.stop(machine.id, machine.provider_config.stop_timeout)
          end
          @app.call(env)
        end
      end
    end
  end
end
