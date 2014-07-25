module VagrantPlugins
  module HyperV
    module Action
      class MessageWillNotDestroy
        def initialize(app, _env)
          @app = app
        end

        def call(env)
          env[:ui].info I18n.t('vagrant.commands.destroy.will_not_destroy',
                               name: env[:machine].name)
          @app.call(env)
        end
      end
    end
  end
end
