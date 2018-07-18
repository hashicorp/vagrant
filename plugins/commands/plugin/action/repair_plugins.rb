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
          @logger = Log4r::Logger.new("vagrant::plugins::plugincommand::repair")
        end

        def call(env)
          env[:ui].info(I18n.t("vagrant.commands.plugin.repairing"))
          plugins = Vagrant::Plugin::Manager.instance.globalize!
          begin
            ENV["VAGRANT_DISABLE_PLUGIN_INIT"] = nil
            Vagrant::Bundler.instance.init!(plugins, :repair)
            ENV["VAGRANT_DISABLE_PLUGIN_INIT"] = "1"
            env[:ui].info(I18n.t("vagrant.commands.plugin.repair_complete"))
          rescue => e
            @logger.error("Failed to repair user installed plugins: #{e.class} - #{e}")
            e.backtrace.each do |backtrace_line|
              @logger.debug(backtrace_line)
            end
            env[:ui].error(I18n.t("vagrant.commands.plugin.repair_failed", message: e.message))
          end
          # Continue
          @app.call(env)
        end
      end

      class RepairPluginsLocal
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant::plugins::plugincommand::repair_local")
        end

        def call(env)
          env[:ui].info(I18n.t("vagrant.commands.plugin.repairing_local"))
          Vagrant::Plugin::Manager.instance.localize!(env[:env]).each_pair do |pname, pinfo|
            env[:env].action_runner.run(Action.action_install,
              plugin_name: pname,
              plugin_entry_point: pinfo["require"],
              plugin_sources: pinfo["sources"],
              plugin_version: pinfo["gem_version"],
              plugin_env_local: true
            )
          end
          env[:ui].info(I18n.t("vagrant.commands.plugin.repair_local_complete"))
          # Continue
          @app.call(env)
        end
      end
    end
  end
end
