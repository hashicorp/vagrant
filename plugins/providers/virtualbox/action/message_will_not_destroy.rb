module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class MessageWillNotDestroy
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].info I18n.t("vagrant.commands.destroy.will_not_destroy",
                              name: env[:machine].name)
          @app.call(env)
        end
      end
    end
  end
end
