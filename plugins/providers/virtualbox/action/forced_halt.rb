module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class ForcedHalt
        def initialize(app, env)
          @app = app
        end

        def call(env)
          current_state = env[:machine].state.id
          if current_state == :running || current_state == :gurumeditation
            env[:ui].info I18n.t("vagrant.actions.vm.halt.force")
            env[:machine].provider.driver.halt
          end

          # Sleep for a second to verify that the VM properly
          # cleans itself up. Silly VirtualBox.
          sleep 1 if !env["vagrant.test"]

          @app.call(env)
        end
      end
    end
  end
end
