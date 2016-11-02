require "vagrant/plugin/manager"

module VagrantPlugins
  module CommandPlugin
    module Action
      # This middleware attempts to repair installed plugins.
      #
      # In general, if plugins are failing to properly load the
      # core issue will likely be one of two issues:
      #   1. manual modifications within ~/.vagrant.d/
      #   2. vagrant upgrade
      # Running an install on configured plugin set will most
      # likely fix these issues, which is all this action does.
      class RepairPlugins
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].info(I18n.t("vagrant.commands.plugin.repairing"))
          plugins = Vagrant::Plugin::Manager.instance.installed_plugins
          Vagrant::Bundler.instance.init!(plugins, :repair)
          env[:ui].info(I18n.t("vagrant.commands.plugin.repair_complete"))

          # Continue
          @app.call(env)
        end
      end
    end
  end
end
