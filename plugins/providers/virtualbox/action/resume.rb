module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class Resume
        def initialize(app, env)
          @app = app
        end

        def call(env)
          current_state = env[:machine].state.id

          if current_state == :paused
            env[:ui].info I18n.t("vagrant.actions.vm.resume.unpausing")
            env[:machine].provider.driver.resume
          elsif current_state == :saved
            env[:ui].info I18n.t("vagrant.actions.vm.resume.resuming")
            env[:action_runner].run(Boot, env)
          end

          @app.call(env)
        end
      end
    end
  end
end
