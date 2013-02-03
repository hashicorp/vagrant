require "rubygems"
require "set"

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
          # Get the list of installed plugins according to the state file
          installed = Set.new(env[:plugin_state_file].installed_plugins)

          # Get the actual specifications of installed gems
          specs = env[:gem_helper].with_environment do
            Gem::Specification.find_all
          end

          # Go through each spec and if it is an installed plugin, then
          # output it. This means that both the installed state and
          # gem match up.
          specs.each do |spec|
            if installed.include?(spec.name)
              # TODO: Formatting
              env[:ui].info spec.name
            end
          end

          @app.call(env)
        end
      end
    end
  end
end
