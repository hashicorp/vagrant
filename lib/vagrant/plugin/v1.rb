require "log4r"

module Vagrant
  module Plugin
    # The superclass for version 1 plugins.
    class V1
      # Exceptions that can be thrown within the plugin interface all
      # inherit from this parent exception.
      class Error < StandardError; end

      # This is thrown when a command name given is invalid.
      class InvalidCommandName < Error; end

      # This is thrown when a hook "position" is invalid.
      class InvalidEasyHookPosition < Error; end

      # Special marker that can be used for action hooks that matches
      # all action sequences.
      ALL_ACTIONS = :__all_actions__

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

      # Registers a callback to be called when a specific action sequence
      # is run. This allows plugin authors to hook into things like VM
      # bootup, VM provisioning, etc.
      #
      # @param [Symbol] name Name of the action.
      # @return [Array] List of the hooks for the given action.
      def self.action_hook(name, &block)
        # Get the list of hooks for the given hook name
        data[:action_hooks] ||= {}
        hooks = data[:action_hooks][name.to_sym] ||= []

        # Return the list if we don't have a block
        return hooks if !block_given?

        # Otherwise add the block to the list of hooks for this action.
        hooks << block
      end

      # Defines additional command line commands available by key. The key
      # becomes the subcommand, so if you register a command "foo" then
      # "vagrant foo" becomes available.
      #
      # @param [String] name Subcommand key.
      def self.command(name=UNSET_VALUE, &block)
        data[:command] ||= Registry.new

        if name != UNSET_VALUE
          # Validate the name of the command
          if name.to_s !~ /^[-a-z0-9]+$/i
            raise InvalidCommandName, "Commands can only contain letters, numbers, and hyphens"
          end

          # Register a new command class only if a name was given.
          data[:command].register(name.to_sym, &block)
        end

        # Return the registry
        data[:command]
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

      # Defines an "easy hook," which gives an easier interface to hook
      # into action sequences.
      def self.easy_hook(position, name, &block)
        if ![:before, :after].include?(position)
          raise InvalidEasyHookPosition, "must be :before, :after"
        end

        # This is the command sent to sequences to insert
        insert_method = "insert_#{position}".to_sym

        # Create the hook
        hook = Easy.create_hook(&block)

        # Define an action hook that listens to all actions and inserts
        # the hook properly if the sequence contains what we're looking for
        action_hook(ALL_ACTIONS) do |seq|
          index = seq.index(name)
          seq.send(insert_method, index, hook) if index
        end
      end

      # Defines an "easy command," which is a command with limited
      # functionality but far less boilerplate required over traditional
      # commands. Easy commands let you make basic commands quickly and
      # easily.
      #
      # @param [String] name Name of the command, how it will be invoked
      #   on the command line.
      def self.easy_command(name, &block)
        command(name) { Easy.create_command(name, &block) }
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

      # Defines an additionally available host implementation with
      # the given key.
      #
      # @param [String] name Name of the host.
      def self.host(name=UNSET_VALUE, &block)
        data[:hosts] ||= Registry.new

        # Register a new host class only if a name was given
        data[:hosts].register(name.to_sym, &block) if name != UNSET_VALUE

        # Return the registry
        data[:hosts]
      end

      # Registers additional provisioners to be available.
      #
      # @param [String] name Name of the provisioner.
      def self.provisioner(name=UNSET_VALUE, &block)
        data[:provisioners] ||= Registry.new

        # Register a new provisioner class only if a name was given
        data[:provisioners].register(name.to_sym, &block) if name != UNSET_VALUE

        # Return the registry
        data[:provisioners]
      end

      # Registers the plugin. This makes the plugin actually work with
      # Vagrant. Prior to registering, the plugin is merely a skeleton.
      #
      # This shouldn't be called by the general public. Plugins are automatically
      # registered when they are given a name.
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
