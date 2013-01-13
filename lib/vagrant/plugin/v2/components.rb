module Vagrant
  module Plugin
    module V2
      # This is the container class for the components of a single plugin.
      # This allows us to separate the plugin class which defines the
      # components, and the actual container of those components. This
      # removes a bit of state overhead from the plugin class itself.
      class Components
        # This contains all the configuration plugins by scope.
        #
        # @return [Hash<Symbol, Registry>]
        attr_reader :configs

        def initialize
          # Create the configs hash which defaults to a registry
          @configs = Hash.new { |h, k| h[k] = Registry.new }
        end
      end
    end
  end
end
