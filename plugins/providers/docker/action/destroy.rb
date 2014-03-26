module VagrantPlugins
  module DockerProvider
    module Action
      class Destroy
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].info I18n.t("vagrant.actions.vm.destroy.destroying")

          machine = env[:machine]
          config  = machine.provider_config
          driver  = machine.provider.driver

          driver.rm(machine.id)
          machine.id = nil

          @app.call env
        end
      end
    end
  end
end
