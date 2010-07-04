module Vagrant
  # Manages action running and registration. Every Vagrant environment
  # has an instance of {Action} to allow for running in the context of
  # the environment.
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
    end

    # The environment to run the actions in.
    attr_reader :env

    # Initializes the action with the given environment which the actions
    # will be run in.
    #
    # @param [Environment] env
    def initialize(env)
      @env = env
    end

    # Runs the given callable object in the context of the environment.
    #
    # @param [Object] callable An object which responds to `call`.
    def run(callable)
      callable.call(Action::Environment.new(env))
    end
  end
end
