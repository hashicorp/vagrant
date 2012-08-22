module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class Suspend
        def initialize(app, env)
          @app = app
        end

        def call(env)
          if env[:machine].provider.state == :running
            env[:ui].info I18n.t("vagrant.actions.vm.suspend.suspending")
            env[:machine].provider.driver.suspend
          end

          @app.call(env)
        end
      end
    end
  end
end
