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

      attr_reader :user_file
      attr_reader :system_file
      attr_reader :local_file

      # @param [Pathname] user_file
      def initialize(user_file)
        @logger = Log4r::Logger.new("vagrant::plugin::manager")
        @user_file   = StateFile.new(user_file)

        system_path  = self.class.system_plugins_file
        @system_file = nil
        @system_file = StateFile.new(system_path) if system_path && system_path.file?

        @local_file = nil
        @globalized = @localized = false
      end

      # Enable global plugins
      #
      # @return [Hash] list of plugins
      def globalize!
        @globalized = true
        @logger.debug("Enabling globalized plugins")
        plugins = installed_plugins
        bundler_init(plugins, global: user_file.path)
        plugins
      end

      # Enable environment local plugins
      #
      # @param [Environment] env Vagrant environment
      # @return [Hash, nil] list of plugins
      def localize!(env)
        @localized = true
        if env.local_data_path
          @logger.debug("Enabling localized plugins")
          @local_file = StateFile.new(env.local_data_path.join("plugins.json"))
          Vagrant::Bundler.instance.environment_path = env.local_data_path
          plugins = local_file.installed_plugins
          bundler_init(plugins, local: local_file.path)
          plugins
        end
      end

      # @return [Boolean] local and global plugins are loaded
      def ready?
        @globalized && @localized
      end

      # Initialize bundler with given plugins
      #
      # @param [Hash] plugins List of plugins
      # @return [nil]
      def bundler_init(plugins, **opts)
        if !Vagrant.plugins_init?
          @logger.warn("Plugin initialization is disabled")
          return nil
        end

        @logger.info("Plugins:")
        plugins.each do |plugin_name, plugin_info|
          installed_version = plugin_info["installed_gem_version"]
          version_constraint = plugin_info["gem_version"]
          installed_version = 'undefined' if installed_version.to_s.empty?
          version_constraint = '> 0' if version_constraint.to_s.empty?
          @logger.info(
            "  - #{plugin_name} = [installed: " \
              "#{installed_version} constraint: " \
              "#{version_constraint}]"
          )
        end
        begin
          Vagrant::Bundler.instance.init!(plugins, **opts)
        rescue StandardError, ScriptError => err
          @logger.error("Plugin initialization error - #{err.class}: #{err}")
          err.backtrace.each do |backtrace_line|
            @logger.debug(backtrace_line)
          end
          raise Vagrant::Errors::PluginInitError, message: err.to_s
        end
      end

      # Installs another plugin into our gem directory.
      #
      # @param [String] name Name of the plugin (gem)
      # @return [Gem::Specification]
      def install_plugin(name, **opts)
        if opts[:env_local] && @local_file.nil?
          raise Errors::PluginNoLocalError
        end

        if name =~ /\.gem$/
          # If this is a gem file, then we install that gem locally.
          local_spec = Vagrant::Bundler.instance.install_local(name, opts)
          name       = local_spec.name
          opts[:version] = local_spec.version.to_s
        end

        plugins = installed_plugins
        plugins[name] = {
          "require"     => opts[:require],
          "gem_version" => opts[:version],
          "sources"     => opts[:sources],
        }

        if local_spec.nil?
          result = nil
          install_lambda = lambda do
            Vagrant::Bundler.instance.install(plugins, opts[:env_local]).each do |spec|
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
        else
          result = local_spec
        end

        if result
          # Add the plugin to the state file
          plugin_file = opts[:env_local] ? @local_file : @user_file
          plugin_file.add_plugin(
            result.name,
            version: opts[:version],
            require: opts[:require],
            sources: opts[:sources],
            env_local: !!opts[:env_local],
            installed_gem_version: result.version.to_s
          )
        else
          r = Gem::Dependency.new(name, opts[:version])
          result = Gem::Specification.find { |s|
            s.satisfies_requirement?(r) &&
              s.activated?
          }
          raise Errors::PluginInstallFailed,
            name: name if result.nil?
          @logger.warn("Plugin install returned no result as no new plugins were installed.")
        end
        # After install clean plugin gems to remove any cruft. This is useful
        # for removing outdated dependencies or other versions of an installed
        # plugin if the plugin is upgraded/downgraded
        Vagrant::Bundler.instance.clean(installed_plugins, local: !!opts[:local])
        result
      rescue Gem::GemNotFoundException
        raise Errors::PluginGemNotFound, name: name
      rescue Gem::Exception => e
        raise Errors::BundlerError, message: e.to_s
      end

      # Uninstalls the plugin with the given name.
      #
      # @param [String] name
      def uninstall_plugin(name, **opts)
        if @system_file
          if !@user_file.has_plugin?(name) && @system_file.has_plugin?(name)
            raise Errors::PluginUninstallSystem,
              name: name
          end
        end

        if opts[:env_local] && @local_file.nil?
          raise Errors::PluginNoLocalError
        end

        plugin_file = opts[:env_local] ? @local_file : @user_file

        if !plugin_file.has_plugin?(name)
          raise Errors::PluginNotInstalled,
            name: name
        end

        plugin_file.remove_plugin(name)

        # Clean the environment, removing any old plugins
        Vagrant::Bundler.instance.clean(installed_plugins)
      rescue Gem::Exception => e
        raise Errors::BundlerError, message: e.to_s
      end

      # Updates all or a specific set of plugins.
      def update_plugins(specific, **opts)
        if opts[:env_local] && @local_file.nil?
          raise Errors::PluginNoLocalError
        end

        plugin_file = opts[:env_local] ? @local_file : @user_file

        result = Vagrant::Bundler.instance.update(plugin_file.installed_plugins, specific)
        plugin_file.installed_plugins.each do |name, info|
          matching_spec = result.detect{|s| s.name == name}
          info = Hash[
            info.map do |key, value|
              [key.to_sym, value]
            end
          ]
          if matching_spec
            plugin_file.add_plugin(name, **info.merge(
              version: "> 0",
              installed_gem_version: matching_spec.version.to_s
            ))
          end
        end
        Vagrant::Bundler.instance.clean(installed_plugins)
        result
      rescue Gem::Exception => e
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
        plugin_list = Util::DeepMerge.deep_merge(system, @user_file.installed_plugins)

        if @local_file
          plugin_list = Util::DeepMerge.deep_merge(plugin_list,
            @local_file.installed_plugins)
        end

        # Sort plugins by name
        Hash[
          plugin_list.map{|plugin_name, plugin_info|
            [plugin_name, plugin_info]
          }.sort_by(&:first)
        ]
      end

      # This returns the list of plugins that are installed as
      # Gem::Specifications.
      #
      # @return [Array<Gem::Specification>]
      def installed_specs
        installed_plugin_info = installed_plugins
        installed = Set.new(installed_plugin_info.keys)
        installed_versions = Hash[
          installed_plugin_info.map{|plugin_name, plugin_info|
            gem_version = plugin_info["gem_version"].to_s
            gem_version = "> 0" if gem_version.empty?
            [plugin_name, Gem::Requirement.new(gem_version)]
          }
        ]

        # Go through the plugins installed in this environment and
        # get the latest version of each.
        installed_map = {}
        Gem::Specification.find_all.each do |spec|
          # Ignore specs that aren't in our installed list
          next if !installed.include?(spec.name)

          next if installed_versions[spec.name] &&
            !installed_versions[spec.name].satisfied_by?(spec.version)

          # If we already have a newer version in our list of installed,
          # then ignore it
          next if installed_map.key?(spec.name) &&
            installed_map[spec.name].version >= spec.version

          installed_map[spec.name] = spec
        end

        installed_map.values
      end

      # Loads the requested plugins into the Vagrant runtime
      #
      # @param [Hash] plugins List of plugins to load
      # @return [nil]
      def load_plugins(plugins)
        if !Vagrant.plugins_enabled?
          @logger.warn("Plugin loading is disabled")
          return
        end

        if plugins.nil?
          @logger.debug("No plugins provided for loading")
          return
        end

        begin
          @logger.info("Loading plugins...")
          plugins.each do |plugin_name, plugin_info|
            if plugin_info["require"].to_s.empty?
              begin
                @logger.info("Loading plugin `#{plugin_name}` with default require: `#{plugin_name}`")
                require plugin_name
              rescue LoadError => err
                if plugin_name.include?("-")
                  plugin_slash = plugin_name.gsub("-", "/")
                  @logger.error("Failed to load plugin `#{plugin_name}` with default require. - #{err.class}: #{err}")
                  @logger.info("Loading plugin `#{plugin_name}` with slash require: `#{plugin_slash}`")
                  require plugin_slash
                else
                  raise
                end
              end
            else
              @logger.debug("Loading plugin `#{plugin_name}` with custom require: `#{plugin_info["require"]}`")
              require plugin_info["require"]
            end
            @logger.debug("Successfully loaded plugin `#{plugin_name}`.")
          end
          if defined?(::Bundler)
            @logger.debug("Bundler detected in use. Loading `:plugins` group.")
            ::Bundler.require(:plugins)
          end
        rescue ScriptError, StandardError => err
          @logger.error("Plugin loading error: #{err.class} - #{err}")
          err.backtrace.each do |backtrace_line|
            @logger.debug(backtrace_line)
          end
          raise Vagrant::Errors::PluginLoadError, message: err.to_s
        end
        nil
      end

      # Check if the requested plugin is installed
      #
      # @param [String] name Name of plugin
      # @param [String] version Specific version of the plugin
      # @return [Boolean]
      def plugin_installed?(name, version=nil)
        # Make the requirement object
        version = Gem::Requirement.new([version.to_s]) if version

        # If plugins are loaded, check for match in loaded specs
        if ready?
          return installed_specs.any? do |s|
            match = s.name == name
            next match if !version
            next match && version.satisfied_by?(s.version)
          end
        end

        # Plugins are not loaded yet so check installed plugin data
        plugin_info = installed_plugins[name]
        return false if !plugin_info
        return !!plugin_info if version.nil? || plugin_info["installed_gem_version"].nil?
        installed_version = Gem::Version.new(plugin_info["installed_gem_version"])
        version.satisfied_by?(installed_version)
      end
    end
  end
end
