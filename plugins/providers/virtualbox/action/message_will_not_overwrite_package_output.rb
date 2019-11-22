module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class MessageWillNotOverwritePackageOutput
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].info I18n.t("vagrant.actions.general.package.output_exists.will_not_overwrite",
                              name: env[:machine].name)
          @app.call(env)
        end
      end
    end
  end
end
