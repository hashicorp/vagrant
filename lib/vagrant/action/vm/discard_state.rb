module Vagrant
  module Action
    module VM
      # Discards the saved state of the VM if its saved. If its
      # not saved, does nothing.
      class DiscardState
        def initialize(app, env)
          @app = app
        end

        def call(env)
          if env[:vm].state == :saved
            env[:ui].info I18n.t("vagrant.actions.vm.discard_state.discarding")
            env[:vm].driver.discard_saved_state
          end

          @app.call(env)
        end
      end
    end
  end
end
