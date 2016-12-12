require "vagrant/plugin/manager"

module VagrantPlugins
  module CommandPlugin
    module Action
      # This middleware lists all the installed plugins.
      #
      # This is a bit more complicated than simply listing installed
      # gems or what is in the state file as installed. Instead, this
      # actually compares installed gems with what the state file claims
      # is installed, and outputs the appropriate truly installed
      # plugins.
      class ListPlugins
        def initialize(app, env)
          @app = app
        end

        def call(env)
          manager = Vagrant::Plugin::Manager.instance
          plugins = manager.installed_plugins
          specs   = Hash[
            manager.installed_specs.map do |spec|
              [spec.name, spec]
            end
          ]

          # Output!
          if specs.empty?
            env[:ui].info(I18n.t("vagrant.commands.plugin.no_plugins"))
            return @app.call(env)
          end

          plugins.each do |plugin_name, plugin|

            spec = specs[plugin_name]
            next if spec.nil?

            system = ""
            system = ", system" if plugin && plugin["system"]
            env[:ui].info "#{spec.name} (#{spec.version}#{system})"
            env[:ui].machine("plugin-name", spec.name)
            env[:ui].machine(
              "plugin-version",
              "#{spec.version}#{system}",
              target: spec.name)

            if plugin["gem_version"] && plugin["gem_version"] != ""
              env[:ui].info(I18n.t(
                "vagrant.commands.plugin.plugin_version",
                version: plugin["gem_version"]))
              env[:ui].machine(
                "plugin-version-constraint",
                plugin["gem_version"],
                target: spec.name)
            end

            if plugin["require"] && plugin["require"] != ""
              env[:ui].info(I18n.t(
                "vagrant.commands.plugin.plugin_require",
                require: plugin["require"]))
              env[:ui].machine(
                "plugin-custom-entrypoint",
                plugin["require"],
                target: spec.name)
            end
          end

          @app.call(env)
        end
      end
    end
  end
end
