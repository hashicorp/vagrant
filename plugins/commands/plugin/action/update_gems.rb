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
          installed_specs = manager.installed_specs
          new_specs       = manager.update_plugins(names)

          updated = {}
          installed_specs.each do |ispec|
            new_specs.each do |uspec|
              next if uspec.name != ispec.name
              next if ispec.version >= uspec.version
              next if updated[uspec.name] && updated[uspec.name].version >= uspec.version

              updated[uspec.name] = uspec
            end
          end

          if updated.empty?
            env[:ui].success(I18n.t("vagrant.commands.plugin.up_to_date"))
          end

          updated.values.each do |spec|
            env[:ui].success(I18n.t("vagrant.commands.plugin.updated",
                                    name: spec.name, version: spec.version.to_s))
          end

          # Continue
          @app.call(env)
        end
      end
    end
  end
end
