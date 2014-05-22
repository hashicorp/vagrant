module VagrantPlugins
  module CommandPlugin
    module Action
      # This middleware uninstalls a plugin by simply removing it from
      # the state file. Running a {PruneGems} after should properly remove
      # it from the gem index.
      class UninstallPlugin
        def initialize(app, env)
          @app = app
        end

        def call(env)
          # Remove it!
          env[:ui].info(I18n.t("vagrant.commands.plugin.uninstalling",
                               name: env[:plugin_name]))

          manager = Vagrant::Plugin::Manager.instance
          manager.uninstall_plugin(env[:plugin_name])

          @app.call(env)
        end
      end
    end
  end
end
