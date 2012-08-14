module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class Destroy
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].info I18n.t("vagrant.actions.vm.destroy.destroying")
          env[:machine].provider.driver.delete
          env[:machine].id = nil

          @app.call(env)
        end
      end
    end
  end
end
