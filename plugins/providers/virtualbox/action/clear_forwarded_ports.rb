module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class ClearForwardedPorts
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].info I18n.t("vagrant.actions.vm.clear_forward_ports.deleting")
          env[:machine].provider.driver.clear_forwarded_ports

          @app.call(env)
        end
      end
    end
  end
end
