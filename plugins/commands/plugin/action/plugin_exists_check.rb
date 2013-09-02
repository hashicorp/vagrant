require "set"

module VagrantPlugins
  module CommandPlugin
    module Action
      # This class checks to see if the plugin is installed already, and
      # if so, raises an exception/error to output to the user.
      class PluginExistsCheck
        def initialize(app, env)
          @app    = app
        end

        def call(env)
          # Get the list of installed plugins according to the state file
          installed = Set.new(env[:plugin_state_file].installed_plugins)
          if !installed.include?(env[:plugin_name])
            raise Vagrant::Errors::PluginNotInstalled,
              name: env[:plugin_name]
          end

          @app.call(env)
        end
      end
    end
  end
end
