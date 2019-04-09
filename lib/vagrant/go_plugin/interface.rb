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
      attach_function :_list_providers, :ListProviders, [], :plugin_result
      attach_function :_list_synced_folders, :ListSyncedFolders, [], :plugin_result

      def initialize
        setup
      end

      # List of provider plugins currently available
      #
      # @return [Hash<String,Hash<Info>>]
      def list_providers
        load_result { _list_providers } || {}
      end

      # List of synced folder plugins currently available
      #
      # @return [Hash<String,Hash<Info>>]
      def list_synced_folders
        load_result { _list_synced_folders } || {}
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
        load_providers
        logger.debug("registering synced folder plugins")
        load_synced_folders
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

      # Load any detected provider plugins
      def load_providers
        if !@_providers_loaded
          @_providers_loaded
          logger.debug("provider go-plugins have not been loaded... loading")
          list_providers.each do |p_name, p_details|
            logger.debug("loading go-plugin provider #{p_name}. details - #{p_details}")
            client = Vagrant::Proto::Provider::Stub.new(
              "#{p_details[:network]}://#{p_details[:address]}",
              :this_channel_is_insecure)
            # Create new provider class wrapper
            provider_klass = Class.new(ProviderPlugin::Provider)
            provider_klass.plugin_client = client
            # Create new plugin to register the provider
            plugin_klass = Class.new(Vagrant.plugin("2"))
            # Define the plugin
            plugin_klass.class_eval do
              name "#{p_name} Provider"
              description p_details[:description]
            end
            # Register the provider
            plugin_klass.provider(p_name.to_sym, priority: p_details.fetch(:priority, 0)) do
              provider_klass
            end
            # Setup any configuration support
            ConfigPlugin.generate_config(client, p_name, plugin_klass, :provider)
            # Register any guest capabilities
            CapabilityPlugin.generate_guest_capabilities(client, plugin_klass, :provider)
            # Register any host capabilities
            CapabilityPlugin.generate_host_capabilities(client, plugin_klass, :provider)
            # Register any provider capabilities
            CapabilityPlugin.generate_provider_capabilities(client, plugin_klass, :provider)
            logger.debug("completed loading provider go-plugin #{p_name}")
            logger.info("loaded go-plugin provider - #{p_name}")
          end
        else
          logger.warn("provider go-plugins have already been loaded. ignoring load request.")
        end
      end

      # Load any detected synced folder plugins
      def load_synced_folders
        if !@_synced_folders_loaded
          @_synced_folders_loaded = true
          logger.debug("synced folder go-plugins have not been loaded... loading")
          Array(list_synced_folders).each do |f_name, f_details|
            logger.debug("loading go-plugin synced folder #{f_name}. details - #{f_details}")
            client = Vagrant::Proto::SyncedFolder::Stub.new(
              "#{p_details[:network]}://#{p_details[:address]}",
              :this_channel_is_insecure)
            # Create new synced folder class wrapper
            folder_klass = Class.new(SyncedFolderPlugin::SyncedFolder)
            folder_klass.plugin_client = client
            # Create new plugin to register the synced folder
            plugin_klass = Class.new(Vagrant.plugin("2"))
            # Define the plugin
            plugin_klass.class_eval do
              name "#{f_name} Synced Folder"
              description f_details[:description]
            end
            # Register the synced folder
            plugin_klass.synced_folder(f_name.to_sym, priority: f_details.fetch(:priority, 10)) do
              folder_klass
            end
            # Register any guest capabilities
            CapabilityPlugin.generate_guest_capabilities(client, plugin_klass, :synced_folder)
            # Register any host capabilities
            CapabilityPlugin.generate_host_capabilities(client, plugin_klass, :synced_folder)
            # Register any provider capabilities
            CapabilityPlugin.generate_provider_capabilities(client, plugin_klass, :synced_folder)
            logger.debug("completed loading synced folder go-plugin #{f_name}")
            logger.info("loaded go-plugin synced folder - #{f_name}")
          end
        else
          logger.warn("synced folder go-plugins have already been loaded. ignoring load request.")
        end
      end
    end
  end
end
