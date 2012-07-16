module Vagrant
  module Plugin
    module V1
      # This is the base class for a provider for the V1 API. A provider
      # is responsible for creating compute resources to match the needs
      # of a Vagrant-configured system.
      class Provider
        # Initialize the provider to represent the given machine.
        #
        # @param [Vagrant::Machine] machine The machine that this provider
        #   is responsible for.
        def initialize(machine)
        end

        # This should return an action callable for the given name.
        #
        # @param [Symbol] name Name of the action.
        # @return [Object] A callable action sequence object, whether it
        #   is a proc, object, etc.
        def action(name)
          nil
        end

        # This should return the state of the machine within this provider.
        # The state can be any symbol.
        #
        # @return [Symbol]
        def state
          nil
        end
      end
    end
  end
end
