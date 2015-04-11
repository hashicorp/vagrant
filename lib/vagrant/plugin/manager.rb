require "pathname"
require "set"

require_relative "../bundler"
require_relative "../shared_helpers"
require_relative "state_file"

module Vagrant
  module Plugin
    # The Manager helps with installing, listing, and initializing plugins.
    class Manager
      # Returns the path to the [StateFile] for user plugins.
      #
      # @return [Pathname]
      def self.user_plugins_file
        Vagrant.user_data_path.join("plugins.json")
      end

      # Returns the path to the [StateFile] for system plugins.
      def self.system_plugins_file
        dir = Vagrant.installer_embedded_dir
        return nil if !dir
        Pathname.new(dir).join("plugins.json")
      end

      def self.instance
        @instance ||= self.new(user_plugins_file)
      end

      # @param [Pathname] user_file
      def initialize(user_file)
        @user_file   = StateFile.new(user_file)

        system_path  = self.class.system_plugins_file
        @system_file = nil
        @system_file = StateFile.new(system_path) if system_path && system_path.file?
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
          opts[:version] = local_spec.version.to_s
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
        @user_file.add_plugin(
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
        if @system_file
          if !@user_file.has_plugin?(name) && @system_file.has_plugin?(name)
            raise Errors::PluginUninstallSystem,
              name: name
          end
        end

        @user_file.remove_plugin(name)

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
        system = {}
        if @system_file
          @system_file.installed_plugins.each do |k, v|
            system[k] = v.merge("system" => true)
          end
        end

        system.merge(@user_file.installed_plugins)
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
          next if installed_map.key?(spec.name) &&
            installed_map[spec.name].version >= spec.version

          installed_map[spec.name] = spec
        end

        installed_map.values
      end
    end
  end
end
