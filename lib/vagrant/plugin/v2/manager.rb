require "log4r"

module Vagrant
  module Plugin
    module V2
      # This class maintains a list of all the registered plugins as well
      # as provides methods that allow querying all registered components of
      # those plugins as a single unit.
      class Manager
        attr_reader :registered

        def initialize
          @logger = Log4r::Logger.new("vagrant::plugin::v2::manager")
          @registered = []
        end

        # This returns all the action hooks.
        #
        # @return [Array]
        def action_hooks(hook_name)
          result = []

          @registered.each do |plugin|
            result += plugin.components.action_hooks[Plugin::ALL_ACTIONS]
            result += plugin.components.action_hooks[hook_name]
          end

          result
        end

        # Find all hooks that are applicable for the given key. This
        # lookup does not include hooks which are defined for ALL_ACTIONS.
        # Key lookups will match on either string or symbol values. The
        # provided keys is broken down into multiple parts for lookups,
        # which allows defining hooks with an entire namespaced name,
        # or a short suffx. For example:
        #
        #  Assume we are given an action class
        #    key = Vagrant::Action::Builtin::SyncedFolders
        #
        #  The list of keys that will be checked for hooks:
        #    ["Vagrant::Action::Builtin::SyncedFolders", "vagrant_action_builtin_synced_folders",
        #     "Action::Builtin::SyncedFolders", "action_builtin_synced_folders",
        #     "Builtin::SyncedFolders", "builtin_synced_folders",
        #     "SyncedFolders", "synced_folders"]
        #
        # @param key [Class, String] key Key for hook lookups
        # @return [Array<Proc>]
        def find_action_hooks(key)
          result = []

          generate_hook_keys(key).each do |k|
            @registered.each do |plugin|
              result += plugin.components.action_hooks[k]
              result += plugin.components.action_hooks[k.to_sym]
            end
          end

          result
        end

        # Generate all valid lookup keys for given key
        #
        # @param [Class, String] key Base key for generation
        # @return [Array<String>] all valid keys
        def generate_hook_keys(key)
          if key.is_a?(Class)
            key = key.name.to_s
          else
            key = key.to_s
          end
          parts = key.split("::")
          [].tap do |keys|
            until parts.empty?
              x = parts.join("::")
              keys << x
              y = x.gsub(/([a-z])([A-Z])/, '\1_\2').gsub('::', '_').downcase
              keys << y if x != y
              parts.shift
            end
          end
        end

        # This returns all the registered commands.
        #
        # @return [Registry<Symbol, Array<Proc, Hash>>]
        def commands
          Registry.new.tap do |result|
            @registered.each do |plugin|
              result.merge!(plugin.components.commands)
            end
          end
        end

        # This returns all the registered communicators.
        #
        # @return [Hash]
        def communicators
          Registry.new.tap do |result|
            @registered.each do |plugin|
              result.merge!(plugin.communicator)
            end
          end
        end

        # This returns all the registered configuration classes.
        #
        # @return [Hash]
        def config
          Registry.new.tap do |result|
            @registered.each do |plugin|
              result.merge!(plugin.components.configs[:top])
            end
          end
        end

        # This returns all the registered guests.
        #
        # @return [Hash]
        def guests
          Registry.new.tap do |result|
            @registered.each do |plugin|
              result.merge!(plugin.components.guests)
            end
          end
        end

        # This returns all the registered guest capabilities.
        #
        # @return [Hash]
        def guest_capabilities
          results = Hash.new { |h, k| h[k] = Registry.new }

          @registered.each do |plugin|
            plugin.components.guest_capabilities.each do |guest, caps|
              results[guest].merge!(caps)
            end
          end

          results
        end

        # This returns all the registered guests.
        #
        # @return [Hash]
        def hosts
          Registry.new.tap do |result|
            @registered.each do |plugin|
              result.merge!(plugin.components.hosts)
            end
          end
        end

        # This returns all the registered host capabilities.
        #
        # @return [Hash]
        def host_capabilities
          results = Hash.new { |h, k| h[k] = Registry.new }

          @registered.each do |plugin|
            plugin.components.host_capabilities.each do |host, caps|
              results[host].merge!(caps)
            end
          end

          results
        end

        # This returns all registered providers.
        #
        # @return [Hash]
        def providers
          Registry.new.tap do |result|
            @registered.each do |plugin|
              result.merge!(plugin.components.providers)
            end
          end
        end

        # This returns all the registered provider capabilities.
        #
        # @return [Hash]
        def provider_capabilities
          results = Hash.new { |h, k| h[k] = Registry.new }

          @registered.each do |plugin|
            plugin.components.provider_capabilities.each do |provider, caps|
              results[provider].merge!(caps)
            end
          end

          results
        end

        # This returns all the config classes for the various providers.
        #
        # @return [Hash]
        def provider_configs
          Registry.new.tap do |result|
            @registered.each do |plugin|
              result.merge!(plugin.components.configs[:provider])
            end
          end
        end

        # This returns all the config classes for the various provisioners.
        #
        # @return [Registry]
        def provisioner_configs
          Registry.new.tap do |result|
            @registered.each do |plugin|
              result.merge!(plugin.components.configs[:provisioner])
            end
          end
        end

        # This returns all registered provisioners.
        #
        # @return [Hash]
        def provisioners
          Registry.new.tap do |result|
            @registered.each do |plugin|
              result.merge!(plugin.provisioner)
            end
          end
        end

        # This returns all registered pushes.
        #
        # @return [Registry]
        def pushes
          Registry.new.tap do |result|
            @registered.each do |plugin|
              result.merge!(plugin.components.pushes)
            end
          end
        end

        # This returns all the config classes for the various pushes.
        #
        # @return [Registry]
        def push_configs
          Registry.new.tap do |result|
            @registered.each do |plugin|
              result.merge!(plugin.components.configs[:push])
            end
          end
        end

        # This returns all synced folder implementations.
        #
        # @return [Registry]
        def synced_folders
          Registry.new.tap do |result|
            @registered.each do |plugin|
              result.merge!(plugin.components.synced_folders)
            end
          end
        end
        
        # This returns all the registered synced folder capabilities.
        #
        # @return [Hash]
        def synced_folder_capabilities
          results = Hash.new { |h, k| h[k] = Registry.new }

          @registered.each do |plugin|
            plugin.components.synced_folder_capabilities.each do |synced_folder, caps|
              results[synced_folder].merge!(caps)
            end
          end

          results
        end
        # This registers a plugin. This should _NEVER_ be called by the public
        # and should only be called from within Vagrant. Vagrant will
        # automatically register V2 plugins when a name is set on the
        # plugin.
        def register(plugin)
          if !@registered.include?(plugin)
            @logger.info("Registered plugin: #{plugin.name}")
            @registered << plugin
          end
        end

        # This clears out all the registered plugins. This is only used by
        # unit tests and should not be called directly.
        def reset!
          @registered.clear
        end

        # This unregisters a plugin so that its components will no longer
        # be used. Note that this should only be used for testing purposes.
        def unregister(plugin)
          if @registered.include?(plugin)
            @logger.info("Unregistered: #{plugin.name}")
            @registered.delete(plugin)
          end
        end
      end
    end
  end
end
