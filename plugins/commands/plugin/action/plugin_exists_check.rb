require 'vagrant/plugin/manager'

module VagrantPlugins
  module CommandPlugin
    module Action
      # This class checks to see if the plugin is installed already, and
      # if so, raises an exception/error to output to the user.
      class PluginExistsCheck
        def initialize(app, _env)
          @app    = app
        end

        def call(env)
          installed = Vagrant::Plugin::Manager.instance.installed_plugins
          unless installed.key?(env[:plugin_name])
            fail Vagrant::Errors::PluginNotInstalled,
                 name: env[:plugin_name]
          end

          @app.call(env)
        end
      end
    end
  end
end
