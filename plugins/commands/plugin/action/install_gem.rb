require "log4r"
require "vagrant/plugin/manager"
require "vagrant/util/platform"

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
          entrypoint  = env[:plugin_entry_point]
          plugin_name = env[:plugin_name]
          sources     = env[:plugin_sources]
          version     = env[:plugin_version]

          # Install the gem
          plugin_name_label = plugin_name
          plugin_name_label += " --version '#{version}'" if version
          env[:ui].info(I18n.t("vagrant.commands.plugin.installing",
                               name: plugin_name_label))

          manager = Vagrant::Plugin::Manager.instance
          plugin_spec = manager.install_plugin(
            plugin_name,
            version: version,
            require: entrypoint,
            sources: sources,
            verbose: !!env[:plugin_verbose],
          )

          # Record it so we can uninstall if something goes wrong
          @installed_plugin_name = plugin_spec.name

          # Tell the user
          env[:ui].success(I18n.t("vagrant.commands.plugin.installed",
                                  name: plugin_spec.name,
                                  version: plugin_spec.version.to_s))

          # If the plugin's spec includes a post-install message display it
          post_install_message = plugin_spec.post_install_message
          if post_install_message
            if post_install_message.is_a?(Array)
              post_install_message = post_install_message.join(" ")
            end

            env[:ui].info(I18n.t("vagrant.commands.plugin.post_install",
                                 name: plugin_spec.name,
                                 message: post_install_message.to_s))
          end

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
