module Vagrant
  class Plugin
    # The superclass for version 1 plugins.
    class V1
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
        # The plugin should be registered if we're setting a real name on it
        register!(self) if name != UNSET_VALUE

        # Get or set the value
        get_or_set(:name, name)
      end

      # Sets a human-friendly descrition of the plugin.
      #
      # @param [String] value Description of the plugin.
      # @return [String] Description of the plugin.
      def self.description(value=UNSET_VALUE)
        get_or_set(:description, value)
      end

      protected

      # Sentinel value denoting that a value has not been set.
      UNSET_VALUE = Object.new

      # Helper method that will set a value if a value is given, or otherwise
      # return the already set value.
      #
      # @param [Symbol] key Key for the data
      # @param [Object] value Value to store.
      # @return [Object] Stored value.
      def self.get_or_set(key, value=UNSET_VALUE)
        @data ||= {}

        # If no value is to be set, then return the value we have already set
        return @data[key] if value.eql?(UNSET_VALUE)

        # Otherwise set the value
        @data[key] = value
      end

      # Registers the plugin. This makes the plugin actually work with
      # Vagrant. Prior to registering, the plugin is merely a skeleton.
      def self.register!(plugin)
        # Register only on the root class
        return V1.register!(plugin) if self != V1

        # Register it into the list
        @registry ||= []
        @registry << plugin if !@registry.include?(plugin)
      end
    end
  end
end
