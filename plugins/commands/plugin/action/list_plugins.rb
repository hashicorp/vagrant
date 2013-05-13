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

          # Go through the plugins installed in this environment and
          # get the latest version of each.
          installed_map = {}
          env[:gem_helper].with_environment do
            Gem::Specification.find_all.each do |spec|
              # Ignore specs that aren't in our installed list
              next if !installed.include?(spec.name)

              # If we already have a newer version in our list of installed,
              # then ignore it
              next if installed_map.has_key?(spec.name) &&
                installed_map[spec.name].version >= spec.version

              installed_map[spec.name] = spec
            end
          end

          # Output!
          if installed_map.empty?
            env[:ui].info(I18n.t("vagrant.commands.plugin.no_plugins"))
          else
            installed_map.values.each do |spec|
              env[:ui].info "#{spec.name} (#{spec.version})"
            end
          end

          @app.call(env)
        end
      end
    end
  end
end
