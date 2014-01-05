require_relative "../shared_helpers"

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
