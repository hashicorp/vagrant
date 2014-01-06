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
          specs = Vagrant::Plugin::Manager.instance.installed_specs

          # Output!
          if specs.empty?
            env[:ui].info(I18n.t("vagrant.commands.plugin.no_plugins"))
          end

          specs.each do |spec|
            env[:ui].info "#{spec.name} (#{spec.version})"
          end

          @app.call(env)
        end
      end
    end
  end
end
