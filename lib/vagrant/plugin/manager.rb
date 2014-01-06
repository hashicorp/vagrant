require "set"

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
      def install_plugin(name, **opts)
        local = false
        if name =~ /\.gem$/
          # If this is a gem file, then we install that gem locally.
          local_spec = Vagrant::Bundler.instance.install_local(name)
          name       = local_spec.name
          opts[:version] = "= #{local_spec.version}"
          local      = true
        end

        plugins = installed_plugins
        plugins[name] = {
          "require"     => opts[:require],
          "gem_version" => opts[:version],
          "sources"     => opts[:sources],
        }

        result = nil
        install_lambda = lambda do
          Vagrant::Bundler.instance.install(plugins, local).each do |spec|
            next if spec.name != name
            next if result && result.version >= spec.version
            result = spec
          end
        end

        if opts[:verbose]
          Vagrant::Bundler.instance.verbose(&install_lambda)
        else
          install_lambda.call
        end

        # Add the plugin to the state file
        @global_file.add_plugin(
          result.name,
          version: opts[:version],
          require: opts[:require],
          sources: opts[:sources],
        )

        result
      rescue ::Bundler::GemNotFound
        raise Errors::PluginGemNotFound, name: name
      rescue ::Bundler::BundlerError => e
        raise Errors::BundlerError, message: e.to_s
      end

      # Uninstalls the plugin with the given name.
      #
      # @param [String] name
      def uninstall_plugin(name)
        @global_file.remove_plugin(name)

        # Clean the environment, removing any old plugins
        Vagrant::Bundler.instance.clean(installed_plugins)
      rescue ::Bundler::BundlerError => e
        raise Errors::BundlerError, message: e.to_s
      end

      # Updates all or a specific set of plugins.
      def update_plugins(specific)
        Vagrant::Bundler.instance.update(installed_plugins, specific)
      rescue ::Bundler::BundlerError => e
        raise Errors::BundlerError, message: e.to_s
      end

      # This returns the list of plugins that should be enabled.
      #
      # @return [Hash]
      def installed_plugins
        @global_file.installed_plugins
      end

      # This returns the list of plugins that are installed as
      # Gem::Specifications.
      #
      # @return [Array<Gem::Specification>]
      def installed_specs
        installed = Set.new(installed_plugins.keys)

        # Go through the plugins installed in this environment and
        # get the latest version of each.
        installed_map = {}
        Gem::Specification.find_all.each do |spec|
          # Ignore specs that aren't in our installed list
          next if !installed.include?(spec.name)

          # If we already have a newer version in our list of installed,
          # then ignore it
          next if installed_map.has_key?(spec.name) &&
            installed_map[spec.name].version >= spec.version

          installed_map[spec.name] = spec
        end

        installed_map.values
      end
    end
  end
end
