require "rubygems"
require "rubygems/gem_runner"

require "log4r"

module VagrantPlugins
  module CommandPlugin
    module Action
      # This action takes the `:plugin_name` variable in the environment
      # and installs it using the RubyGems API.
      class InstallGem
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::plugins::plugincommand::installgem")
        end

        def call(env)
          plugin_name = env[:plugin_name]

          # Install the gem
          env[:ui].info(I18n.t("vagrant.commands.plugin.installing",
                               :name => plugin_name))
          env[:gem_helper].cli(["install", plugin_name, "--no-ri", "--no-rdoc"])

          # Mark that we installed the gem
          env[:plugin_state_file].add_plugin(plugin_name)

          # Continue
          @app.call(env)
        end
      end
    end
  end
end
