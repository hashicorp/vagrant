module VagrantPlugins
  module CommandPlugin
    module Action
      class UninstallGoPlugin
        def initialize(app, env)
          @app = app
        end

        def call(env)
          # Remove it!
          env[:ui].info(I18n.t("vagrant.commands.plugin.uninstalling",
            name: env[:plugin_name]))

          manager = Vagrant::GoPlugin::Manager.instance
          manager.uninstall_plugin(env[:plugin_name])

          @app.call(env)
        end
      end
    end
  end
end
