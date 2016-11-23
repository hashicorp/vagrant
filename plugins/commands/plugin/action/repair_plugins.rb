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
          plugins = Vagrant::Plugin::Manager.instance.installed_plugins
          begin
            Vagrant::Bundler.instance.init!(plugins, :repair)
            env[:ui].info(I18n.t("vagrant.commands.plugin.repair_complete"))
          rescue Exception => e
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
    end
  end
end
