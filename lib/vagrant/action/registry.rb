module Vagrant
  module Action
    # This is the action registry, which stores action steps indexed
    # by a unique name. These registry names can be used to call actions
    # via the `Runner` class.
    class Registry
      def initialize
        @actions = {}
      end

      # Register a callable by key.
      #
      # The callable should be given in a block which will be lazily evaluated
      # when the action is needed.
      #
      # If an action by the given name already exists then it will be
      # overwritten.
      def register(key, &block)
        @actions[key] = block
      end

      # Get an action by the given key.
      #
      # This will evaluate the block given to `register` and return the resulting
      # action stack.
      def get(key)
        return nil if !@actions.has_key?(key)
        @actions[key].call
      end
    end
  end
end
