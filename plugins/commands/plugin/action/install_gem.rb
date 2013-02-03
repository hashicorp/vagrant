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

          # First, install the gem
          begin
            # Set the GEM_HOME so that it is installed into our local gems path
            old_gem_home = ENV["GEM_HOME"]
            ENV["GEM_HOME"] = env[:gems_path].to_s
            p ENV["GEM_PATH"]
            @logger.debug("Set GEM_HOME to: #{ENV["GEM_HOME"]}")

            @logger.info("Installing gem: #{plugin_name}")
            env[:ui].info(
              I18n.t("vagrant.commands.plugin.installing", :name => plugin_name))
            Gem.clear_paths
            Gem::GemRunner.new.run(
              ["install", plugin_name, "--no-ri", "--no-rdoc"])
          ensure
            ENV["GEM_HOME"] = old_gem_home
          end

          # Mark that we installed the gem
          env[:plugin_state_file].add_plugin(plugin_name)

          # Continue
          @app.call(env)
        end
      end
    end
  end
end
