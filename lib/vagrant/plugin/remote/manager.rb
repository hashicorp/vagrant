require "log4r"

module Vagrant
  module Plugin
    module Remote
      # This class maintains a list of all the registered plugins as well
      # as provides methods that allow querying all registered components of
      # those plugins as a single unit.
      class Manager
        def self.prepended(klass)
          klass.class_eval do
            attr_accessor :basis_client
          end
        end

        def initialize()
          @logger = Log4r::Logger.new("vagrant::plugin::remote::manager")
          @registered = {}
        end

         # This returns all the registered communicators.
        #
        # @return [Hash]
        def communicators
          registered[:communincator]
        end

        # This returns all the registered guests.
        #
        # @return [Hash]
        def guests
          registered[:guest]
        end

        # This returns all the registered guests.
        #
        # @return [Hash]
        def hosts
          registered[:host]
        end

        # This returns all synced folder implementations.
        #
        # @return [Registry]
        def synced_folders
          @registered[:synced_folder]
        end

        # This registers a plugin. This should _NEVER_ be called by the public
        # and should only be called from within Vagrant. Vagrant will
        # automatically register V2 plugins when a name is set on the
        # plugin.
        def register(type, plugin)
          @registered[type] ||= {}
          if !@registered[type].include?(plugin)
            @logger.debug("registering #{plugin.keys}")
            @registered[type].merge!(plugin)
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
          if @registered[type].include?(plugin)
            @logger.info("Unregistered: #{plugin.name}")
            @registered[type].delete(plugin)
          end
        end
      end
    end
  end
end
