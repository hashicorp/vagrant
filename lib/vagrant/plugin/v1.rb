require "log4r"

module Vagrant
  class Plugin
    # The superclass for version 1 plugins.
    class V1
      LOGGER = Log4r::Logger.new("vagrant::plugin::v1")

      # Returns a list of registered plugins for this version.
      #
      # @return [Array]
      def self.registered
        @registry || []
      end

      # Set the name of the plugin. The moment that this is called, the
      # plugin will be registered and available. Before this is called, a
      # plugin does not exist. The name must be unique among all installed
      # plugins.
      #
      # @param [String] name Name of the plugin.
      # @return [String] The name of the plugin.
      def self.name(name=UNSET_VALUE)
        # Get or set the value first, so we have a name for logging when
        # we register.
        result = get_or_set(:name, name)

        # The plugin should be registered if we're setting a real name on it
        register! if name != UNSET_VALUE

        # Return the result
        result
      end

      # Sets a human-friendly descrition of the plugin.
      #
      # @param [String] value Description of the plugin.
      # @return [String] Description of the plugin.
      def self.description(value=UNSET_VALUE)
        get_or_set(:description, value)
      end

      # Defines additional configuration keys to be available in the
      # Vagrantfile. The configuration class should be returned by a
      # block passed to this method. This is done to ensure that the class
      # is lazy loaded, so if your class inherits from any classes that
      # are specific to Vagrant 1.0, then the plugin can still be defined
      # without breaking anything in future versions of Vagrant.
      #
      # @param [String] name Configuration key.
      def self.config(name=UNSET_VALUE, &block)
        data[:config] ||= Registry.new

        # Register a new config class only if a name was given.
        data[:config].register(name.to_sym, &block) if name != UNSET_VALUE

        # Return the registry
        data[:config]
      end

      # Defines an additionally available guest implementation with
      # the given key.
      #
      # @param [String] name Name of the guest.
      def self.guest(name=UNSET_VALUE, &block)
        data[:guests] ||= Registry.new

        # Register a new guest class only if a name was given
        data[:guests].register(name.to_sym, &block) if name != UNSET_VALUE

        # Return the registry
        data[:guests]
      end

      # Registers the plugin. This makes the plugin actually work with
      # Vagrant. Prior to registering, the plugin is merely a skeleton.
      def self.register!(plugin=nil)
        plugin ||= self

        # Register only on the root class
        return V1.register!(plugin) if self != V1

        # Register it into the list
        @registry ||= []
        if !@registry.include?(plugin)
          LOGGER.info("Registered plugin: #{plugin.name}")
          @registry << plugin
        end
      end

      # This unregisters the plugin. Note that to re-register the plugin
      # you must call `register!` again.
      def self.unregister!(plugin=nil)
        plugin ||= self

        # Unregister only on the root class
        return V1.unregister!(plugin) if self != V1

        # Unregister it from the registry
        @registry ||= []
        if @registry.include?(plugin)
          LOGGER.info("Unregistered: #{plugin.name}")
          @registry.delete(plugin)
        end
      end

      protected

      # Sentinel value denoting that a value has not been set.
      UNSET_VALUE = Object.new

      # Returns the internal data associated with this plugin.
      #
      # @return [Hash]
      def self.data
        @data ||= {}
      end

      # Helper method that will set a value if a value is given, or otherwise
      # return the already set value.
      #
      # @param [Symbol] key Key for the data
      # @param [Object] value Value to store.
      # @return [Object] Stored value.
      def self.get_or_set(key, value=UNSET_VALUE)
        # If no value is to be set, then return the value we have already set
        return data[key] if value.eql?(UNSET_VALUE)

        # Otherwise set the value
        data[key] = value
      end
    end
  end
end
