require "rubygems"
require "rubygems/dependency_installer"

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
          prerelease  = env[:plugin_prerelease]
          version     = env[:plugin_version]

          # Install the gem
          plugin_name_label = plugin_name
          plugin_name_label += ' --prerelease' if prerelease
          plugin_name_label += " --version '#{version}'" if version
          env[:ui].info(I18n.t("vagrant.commands.plugin.installing",
                               :name => plugin_name_label))
          installed_gems = env[:gem_helper].with_environment do
            # Override the list of sources by the ones set as a parameter if given
            if env[:plugin_sources]
              @logger.info("Custom plugin sources: #{env[:plugin_sources]}")
              Gem.sources = env[:plugin_sources]
            end

            installer = Gem::DependencyInstaller.new(:document => [], :prerelease => prerelease)

            begin
              installer.install(plugin_name, version)
            rescue Gem::GemNotFoundException
              raise Vagrant::Errors::PluginInstallNotFound,
                :name => plugin_name
            end
          end

          # The plugin spec is the last installed gem since RubyGems
          # currently always installed the requested gem last.
          @logger.debug("Installed #{installed_gems.length} gems.")
          plugin_spec = installed_gems.last

          # Store the installed name so we can uninstall it if things go
          # wrong.
          @installed_plugin_name = plugin_spec.name

          # Mark that we installed the gem
          @logger.info("Adding the plugin to the state file...")
          env[:plugin_state_file].add_plugin(plugin_spec.name)

          # Tell the user
          env[:ui].success(I18n.t("vagrant.commands.plugin.installed",
                                  :name => plugin_spec.name,
                                  :version => plugin_spec.version.to_s))

          # Continue
          @app.call(env)
        end

        def recover(env)
          # If any error happens, we uninstall it and remove it from
          # the state file. We can only do this if we successfully installed
          # the gem in the first place.
          if @installed_plugin_name
            new_env = env.dup
            new_env.delete(:interrupted)
            new_env[:plugin_name] = @installed_plugin_name
            new_env[:action_runner].run(Action.action_uninstall, new_env)
          end
        end
      end
    end
  end
end
