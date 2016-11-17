require "vagrant/plugin/manager"

module VagrantPlugins
  module CommandPlugin
    module Action
      class UpdateGems
        def initialize(app, env)
          @app    = app
        end

        def call(env)
          names = env[:plugin_name] || []

          if names.empty?
            env[:ui].info(I18n.t("vagrant.commands.plugin.updating"))
          else
            env[:ui].info(I18n.t("vagrant.commands.plugin.updating_specific",
                                 names: names.join(", ")))
          end

          manager = Vagrant::Plugin::Manager.instance
          installed_plugins = manager.installed_plugins
          new_specs       = manager.update_plugins(names)
          updated_plugins = manager.installed_plugins

          updated = {}
          installed_plugins.each do |name, info|
            update = updated_plugins[name]
            if update && update["installed_gem_version"] != info["installed_gem_version"]
              updated[name] = update["installed_gem_version"]
            end
          end

          if updated.empty?
            env[:ui].success(I18n.t("vagrant.commands.plugin.up_to_date"))
          end

          updated.each do |name, version|
            env[:ui].success(I18n.t("vagrant.commands.plugin.updated",
                                    name: name, version: version.to_s))
          end

          # Continue
          @app.call(env)
        end
      end
    end
  end
end
