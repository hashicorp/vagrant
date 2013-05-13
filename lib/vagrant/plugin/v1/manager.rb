require "log4r"

module Vagrant
  module Plugin
    module V1
      # This class maintains a list of all the registered plugins as well
      # as provides methods that allow querying all registered components of
      # those plugins as a single unit.
      class Manager
        attr_reader :registered

        def initialize
          @logger = Log4r::Logger.new("vagrant::plugin::v1::manager")
          @registered = []
        end

        # This returns all the registered communicators.
        #
        # @return [Hash]
        def communicators
          result = {}

          @registered.each do |plugin|
            result.merge!(plugin.communicator.to_hash)
          end

          result
        end

        # This returns all the registered configuration classes.
        #
        # @return [Hash]
        def config
          result = {}

          @registered.each do |plugin|
            plugin.config.each do |key, klass|
              result[key] = klass
            end
          end

          result
        end

        # This returns all the registered configuration classes that were
        # marked as "upgrade safe."
        #
        # @return [Hash]
        def config_upgrade_safe
          result = {}

          @registered.each do |plugin|
            configs = plugin.data[:config_upgrade_safe]
            if configs
              configs.each do |key|
                result[key] = plugin.config.get(key)
              end
            end
          end

          result
        end

        # This returns all the registered guests.
        #
        # @return [Hash]
        def guests
          result = {}

          @registered.each do |plugin|
            result.merge!(plugin.guest.to_hash)
          end

          result
        end

        # This returns all registered host classes.
        #
        # @return [Hash]
        def hosts
          hosts = {}

          @registered.each do |plugin|
            hosts.merge!(plugin.host.to_hash)
          end

          hosts
        end

        # This returns all registered providers.
        #
        # @return [Hash]
        def providers
          providers = {}

          @registered.each do |plugin|
            providers.merge!(plugin.provider.to_hash)
          end

          providers
        end

        # This registers a plugin. This should _NEVER_ be called by the public
        # and should only be called from within Vagrant. Vagrant will
        # automatically register V1 plugins when a name is set on the
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
