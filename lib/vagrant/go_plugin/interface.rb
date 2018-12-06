require "log4r"
require "vagrant/go_plugin/core"

module Vagrant
  module GoPlugin
    # Interface for go-plugin integration
    class Interface
      include Core

      # go plugin functions
      typedef :bool, :enable_logger
      typedef :bool, :timestamps
      typedef :string, :log_level
      typedef :string, :plugin_directory

      attach_function :_setup, :Setup, [:enable_logger, :timestamps, :log_level], :bool
      attach_function :_teardown, :Teardown, [], :void
      attach_function :_load_plugins, :LoadPlugins, [:plugin_directory], :bool

      def initialize
        setup
      end

      # Load any plugins found at the given directory
      #
      # @param [String, Pathname] path Directory to load
      def load_plugins(path)
        logger.debug("loading plugins from path: #{path}")
        if !File.directory?(path.to_s)
          raise ArgumentError, "Directory expected for plugin loading"
        end
        _load_plugins(path.to_s)
      end

      # Register all available plugins
      def register_plugins
        logger.debug("registering provider plugins")
        ProviderPlugin.interface.load!
        logger.debug("registering synced folder plugins")
        SyncedFolderPlugin.interface.load!
      end

      # Load the plugins found at the given directory
      #
      # @param [String] plugin_directory Directory containing go-plugins
      def setup
        if !@setup
          @setup = true
          Kernel.at_exit { Vagrant::GoPlugin.interface.teardown }
          logger.debug("running go-plugin interface setup")
          _setup(!Vagrant.log_level.to_s.empty?,
            !!ENV["VAGRANT_LOG_TIMESTAMP"],
            Vagrant.log_level.to_s)
        else
          logger.warn("go-plugin interface already setup")
        end
      end

      # Teardown any plugins that may be currently active
      def teardown
        logger.debug("starting teardown of go-plugin interface")
        _teardown
        logger.debug("teardown of go-plugin interface complete")
      end

      # @return [Boolean] go plugins have been setup
      def configured?
        !!@setup
      end
    end
  end
end
