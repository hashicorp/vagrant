module Vagrant
  module Plugin
    module V2
      # This is the container class for the components of a single plugin.
      # This allows us to separate the plugin class which defines the
      # components, and the actual container of those components. This
      # removes a bit of state overhead from the plugin class itself.
      class Components
        # This contains all the action hooks.
        #
        # @return [Hash<Symbol, Array>]
        attr_reader :action_hooks

        # This contains all the command plugins by name, and returns
        # the command class and options. The command class is wrapped
        # in a Proc so that it can be lazy loaded.
        #
        # @return [Registry<Symbol, Array<Proc, Hash>>]
        attr_reader :commands

        # This contains all the configuration plugins by scope.
        #
        # @return [Hash<Symbol, Registry>]
        attr_reader :configs

        # This contains all the guests and their parents.
        #
        # @return [Registry<Symbol, Array<Class, Symbol>>]
        attr_reader :guests

        # This contains all the registered guest capabilities.
        #
        # @return [Hash<Symbol, Registry>]
        attr_reader :guest_capabilities

        # This contains all the hosts and their parents.
        #
        # @return [Registry<Symbol, Array<Class, Symbol>>]
        attr_reader :hosts

        # This contains all the registered host capabilities.
        #
        # @return [Hash<Symbol, Registry>]
        attr_reader :host_capabilities

        # This contains all the provider plugins by name, and returns
        # the provider class and options.
        #
        # @return [Hash<Symbol, Registry>]
        attr_reader :providers

        # This contains all the registered provider capabilities.
        #
        # @return [Hash<Symbol, Registry>]
        attr_reader :provider_capabilities

        # This contains all the push implementations by name.
        #
        # @return [Registry<Symbol, Array<Class, Hash>>]
        attr_reader :pushes

        # This contains all the synced folder implementations by name.
        #
        # @return [Registry<Symbol, Array<Class, Integer>>]
        attr_reader :synced_folders

        def initialize
          # The action hooks hash defaults to []
          @action_hooks = Hash.new { |h, k| h[k] = [] }

          @commands = Registry.new
          @configs = Hash.new { |h, k| h[k] = Registry.new }
          @guests  = Registry.new
          @guest_capabilities = Hash.new { |h, k| h[k] = Registry.new }
          @hosts   = Registry.new
          @host_capabilities = Hash.new { |h, k| h[k] = Registry.new }
          @providers = Registry.new
          @provider_capabilities = Hash.new { |h, k| h[k] = Registry.new }
          @pushes = Registry.new
          @synced_folders = Registry.new
        end
      end
    end
  end
end
