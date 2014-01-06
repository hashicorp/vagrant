require_relative "../bundler"
require_relative "../shared_helpers"
require_relative "state_file"

module Vagrant
  module Plugin
    # The Manager helps with installing, listing, and initializing plugins.
    class Manager
      # Returns the path to the [StateFile] for global plugins.
      #
      # @return [Pathname]
      def self.global_plugins_file
        Vagrant.user_data_path.join("plugins.json")
      end

      def self.instance
        @instance ||= self.new(global_plugins_file)
      end

      # @param [Pathname] global_file
      def initialize(global_file)
        @global_file = StateFile.new(global_file)
      end

      # Installs another plugin into our gem directory.
      #
      # @param [String] name Name of the plugin (gem)
      # @return [Gem::Specification]
      def install_plugin(name)
        result = nil
        Vagrant::Bundler.instance.install(installed_plugins.push(name)).each do |spec|
          next if spec.name != name
          next if result && result.version >= spec.version
          result = spec
        end

        # Add the plugin to the state file
        @global_file.add_plugin(result.name)

        result
      end

      # Uninstalls the plugin with the given name.
      #
      # @param [String] name
      def uninstall_plugin(name)
        @global_file.remove_plugin(name)

        # Clean the environment, removing any old plugins
        Vagrant::Bundler.instance.clean(installed_plugins)
      end

      # This returns the list of plugins that should be enabled.
      #
      # @return [Array<String>]
      def installed_plugins
        @global_file.installed_plugins.keys
      end

      # This returns the list of plugins that are installed as
      # Gem::Specifications.
      #
      # @return [Array<Gem::Specification>]
      def installed_specs
        ::Bundler.load.specs
      end
    end
  end
end
