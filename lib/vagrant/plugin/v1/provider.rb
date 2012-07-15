module Vagrant
  module Plugin
    module V1
      # This is the base class for a provider for the V1 API. A provider
      # is responsible for creating compute resources to match the needs
      # of a Vagrant-configured system.
      class Provider
        # This should return an action callable for the given name.
        #
        # @param [Symbol] name Name of the action.
        # @return [Object] A callable action sequence object, whether it
        #   is a proc, object, etc.
        def action(name)
          nil
        end
      end
    end
  end
end
