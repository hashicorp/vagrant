require "set"

require "log4r"

require "vagrant/plugin/v2/components"

module Vagrant
  module Plugin
    module V2
      # This is the superclass for all V2 plugins.
      class Plugin
        # Special marker that can be used for action hooks that matches
        # all action sequences.
        ALL_ACTIONS = :__all_actions__

        # The logger for this class.
        LOGGER = Log4r::Logger.new("vagrant::plugin::v2::plugin")

        # Set the root class up to be ourself, so that we can reference this
        # from within methods which are probably in subclasses.
        ROOT_CLASS = self

        # This returns the manager for all V2 plugins.
        #
        # @return [V2::Manager]
        def self.manager
          @manager ||= Manager.new
        end

        # Returns the {Components} for this plugin.
        #
        # @return [Components]
        def self.components
          @components ||= Components.new
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
        # @param [String] name Name of the action.
        # @param [Symbol] hook_name The location to hook. If this isn't
        #   set, every middleware action is hooked.
        # @return [Array] List of the hooks for the given action.
        def self.action_hook(name, hook_name=nil, &block)
          # The name is currently not used but we want it for the future.

          hook_name ||= ALL_ACTIONS
          components.action_hooks[hook_name.to_sym] << block
        end

        # Defines additional command line commands available by key. The key
        # becomes the subcommand, so if you register a command "foo" then
        # "vagrant foo" becomes available.
        #
        # @param [String] name Subcommand key.
        def self.command(name, **opts, &block)
          # Validate the name of the command
          if name.to_s !~ /^[-a-z0-9]+$/i
            raise InvalidCommandName, "Commands can only contain letters, numbers, and hyphens"
          end

          # By default, the command is primary
          opts[:primary] = true if !opts.key?(:primary)

          # Register the command
          components.commands.register(name.to_sym) do
            [block, opts]
          end

          nil
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
        def self.config(name, scope=nil, &block)
          scope ||= :top
          components.configs[scope].register(name.to_sym, &block)
          nil
        end

        # Defines an additionally available guest implementation with
        # the given key.
        #
        # @param [String] name Name of the guest.
        # @param [String] parent Name of the parent guest (if any)
        def self.guest(name, parent=nil, &block)
          components.guests.register(name.to_sym) do
            parent = parent.to_sym if parent

            [block.call, parent]
          end
          nil
        end

        # Defines a capability for the given guest. The block should return
        # a class/module that has a method with the capability name, ready
        # to be executed. This means that if it is an instance method,
        # the block should return an instance of the class.
        #
        # @param [String] guest The name of the guest
        # @param [String] cap The name of the capability
        def self.guest_capability(guest, cap, &block)
          components.guest_capabilities[guest.to_sym].register(cap.to_sym, &block)
          nil
        end

        # Defines an additionally available host implementation with
        # the given key.
        #
        # @param [String] name Name of the host.
        # @param [String] parent Name of the parent host (if any)
        def self.host(name, parent=nil, &block)
          components.hosts.register(name.to_sym) do
            parent = parent.to_sym if parent

            [block.call, parent]
          end
          nil
        end

        # Defines a capability for the given host. The block should return
        # a class/module that has a method with the capability name, ready
        # to be executed. This means that if it is an instance method,
        # the block should return an instance of the class.
        #
        # @param [String] host The name of the host
        # @param [String] cap The name of the capability
        def self.host_capability(host, cap, &block)
          components.host_capabilities[host.to_sym].register(cap.to_sym, &block)
          nil
        end

        # Registers additional providers to be available.
        #
        # @param [Symbol] name Name of the provider.
        def self.provider(name=UNSET_VALUE, options=nil, &block)
          options ||= {}
          options[:priority] ||= 5

          components.providers.register(name.to_sym) do
            [block.call, options]
          end

          nil
        end

        # Defines a capability for the given provider. The block should return
        # a class/module that has a method with the capability name, ready
        # to be executed. This means that if it is an instance method,
        # the block should return an instance of the class.
        #
        # @param [String] provider The name of the provider
        # @param [String] cap The name of the capability
        def self.provider_capability(provider, cap, &block)
          components.provider_capabilities[provider.to_sym].register(cap.to_sym, &block)
          nil
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

        # Registers additional pushes to be available.
        #
        # @param [String] name Name of the push.
        # @param [Hash] options List of options for the push.
        def self.push(name, options=nil, &block)
          components.pushes.register(name.to_sym) do
            [block.call, options]
          end

          nil
        end

        # Registers additional synced folder implementations.
        #
        # @param [String] name Name of the implementation.
        # @param [Integer] priority The priority of the implementation,
        # higher (big) numbers are tried before lower (small) numbers.
        def self.synced_folder(name, priority=10, &block)
          components.synced_folders.register(name.to_sym) do
            [block.call, priority]
          end

          nil
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
