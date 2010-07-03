module Vagrant
  class Action
    class << self
      # Returns the list of registered actions.
      def actions
        @actions ||= {}
      end

      # Registers an action and associates it with a symbol. This
      # symbol can then be referenced in other action builds and
      # callbacks can be registered on that symbol.
      #
      # @param [Symbol] key
      def register(key, callable)
        @actions[key] = callable
      end

      # Runs a registered action with the given key.
      #
      # @param [Symbol] key
      def run(key)
        @actions[key].call
      end
    end
  end
end
