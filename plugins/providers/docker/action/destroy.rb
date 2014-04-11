module VagrantPlugins
  module DockerProvider
    module Action
      class Destroy
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].info I18n.t("docker_provider.messages.destroying")

          machine = env[:machine]
          driver  = machine.provider.driver

          driver.rm(machine.id)
          machine.id = nil

          @app.call env
        end
      end
    end
  end
end
