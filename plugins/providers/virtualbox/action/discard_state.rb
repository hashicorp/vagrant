module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class DiscardState
        def initialize(app, env)
          @app = app
        end

        def call(env)
          if env[:machine].state.id == :saved
            env[:ui].info I18n.t("vagrant.actions.vm.discard_state.discarding")
            env[:machine].provider.driver.discard_saved_state
          end

           @app.call(env)
        end
      end
    end
  end
end
