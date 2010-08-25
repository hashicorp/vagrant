module Vagrant
  # Manages action running and registration. Every Vagrant environment
  # has an instance of {Action} to allow for running in the context of
  # the environment.
  class Action
    include Util

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
        actions[key] = callable
      end

      # Retrieves a registered action by key.
      def [](key)
        actions[key]
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
    # If a symbol is given as the `callable` parameter, then it is looked
    # up in the registered actions list which are registered with {register}.
    #
    # @param [Object] callable An object which responds to `call`.
    def run(callable, options=nil)
      callable = Builder.new.use(callable) if callable.kind_of?(Class)
      callable = self.class.actions[callable] if callable.kind_of?(Symbol)
      raise Exceptions::UncallableAction.new(callable) if !callable

      action_environment = Action::Environment.new(env)
      action_environment.merge!(options || {})

      # Run the action chain in a busy block, marking the environment as
      # interrupted if a SIGINT occurs, and exiting cleanly once the
      # chain has been run.
      int_callback = lambda do
        if action_environment.interrupted?
          env.logger.info "Exiting immediately!"
          abort
        end

        env.logger.info "Waiting for cleanup before exiting..."
        action_environment.error!(:interrupt)
      end

      Busy.busy(int_callback) { callable.call(action_environment) }
    end
  end
end
