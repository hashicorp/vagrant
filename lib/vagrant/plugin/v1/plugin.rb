require "set"

require "log4r"

module Vagrant
  module Plugin
    module V1
      # This is the superclass for all V1 plugins.
      class Plugin
        # Special marker that can be used for action hooks that matches
        # all action sequences.
        ALL_ACTIONS = :__all_actions__

        # The logger for this class.
        LOGGER = Log4r::Logger.new("vagrant::plugin::v1::plugin")

        # Set the root class up to be ourself, so that we can reference this
        # from within methods which are probably in subclasses.
        ROOT_CLASS = self

        # This returns the manager for all V1 plugins.
        #
        # @return [V1::Manager]
        def self.manager
          @manager ||= Manager.new
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
          Plugin.manager.register(self) if name != UNSET_VALUE

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

        # Defines additional communicators to be available. Communicators
        # should be returned by a block passed to this method. This is done
        # to ensure that the class is lazy loaded, so if your class inherits
        # from or uses any Vagrant internals specific to Vagrant 1.0, then
        # the plugin can still be defined without breaking anything in future
        # versions of Vagrant.
        #
        # @param [String] name Communicator name.
        def self.communicator(name=UNSET_VALUE, &block)
          data[:communicator] ||= Registry.new

          # Register a new communicator class only if a name was given.
          data[:communicator].register(name.to_sym, &block) if name != UNSET_VALUE

          # Return the registry
          data[:communicator]
        end

        # Defines additional configuration keys to be available in the
        # Vagrantfile. The configuration class should be returned by a
        # block passed to this method. This is done to ensure that the class
        # is lazy loaded, so if your class inherits from any classes that
        # are specific to Vagrant 1.0, then the plugin can still be defined
        # without breaking anything in future versions of Vagrant.
        #
        # @param [String] name Configuration key.
        # @param [Boolean] upgrade_safe If this is true, then this configuration
        #   key is safe to load during an upgrade, meaning that it depends
        #   on NO Vagrant internal classes. Do _not_ set this to true unless
        #   you really know what you're doing, since you can cause Vagrant
        #   to crash (although Vagrant will output a user-friendly error
        #   message if this were to happen).
        def self.config(name=UNSET_VALUE, upgrade_safe=false, &block)
          data[:config] ||= Registry.new

          # Register a new config class only if a name was given.
          if name != UNSET_VALUE
            data[:config].register(name.to_sym, &block)

            # If we were told this is an upgrade safe configuration class
            # then we add it to the set.
            if upgrade_safe
              data[:config_upgrade_safe] ||= Set.new
              data[:config_upgrade_safe].add(name.to_sym)
            end
          end

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

        # Registers additional providers to be available.
        #
        # @param [Symbol] name Name of the provider.
        def self.provider(name=UNSET_VALUE, &block)
          data[:providers] ||= Registry.new

          # Register a new provider class only if a name was given
          data[:providers].register(name.to_sym, &block) if name != UNSET_VALUE

          # Return the registry
          data[:providers]
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

        # Returns the internal data associated with this plugin. This
        # should NOT be called by the general public.
        #
        # @return [Hash]
        def self.data
          @data ||= {}
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
          # If no value is to be set, then return the value we have already set
          return data[key] if value.eql?(UNSET_VALUE)

          # Otherwise set the value
          data[key] = value
        end
      end
    end
  end
end
