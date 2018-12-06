require "log4r"
require "vagrant/go_plugin/manager"

module VagrantPlugins
  module CommandPlugin
    module Action
      class InstallGoPlugin
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::plugins::plugincommand::installgoplugin")
        end

        def call(env)
          plugin_name = env[:plugin_name]
          plugin_source = env[:plugin_source]

          manager = Vagrant::GoPlugin::Manager.instance

          env[:ui].info(I18n.t("vagrant.commands.plugin.installing",
            name: plugin_name))

          manager.install_plugin(plugin_name, plugin_source)

          # Tell the user
          env[:ui].success(I18n.t("vagrant.commands.plugin.installed",
                                  name: plugin_name,
                                  version: plugin_source))

          # Continue
          @app.call(env)
        end
      end
    end
  end
end
