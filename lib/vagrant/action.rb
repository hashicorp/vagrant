require 'vagrant/action/builder'
require 'vagrant/action/builtin'

# The builtin middlewares
require 'vagrant/action/box'
require 'vagrant/action/env'
require 'vagrant/action/general'
require 'vagrant/action/vm'

module Vagrant
  # Manages action running and registration. Every Vagrant environment
  # has an instance of {Action} to allow for running in the context of
  # the environment, which is accessible at {Environment#actions}. Actions
  # are the foundation of most functionality in Vagrant, and are implemented
  # architecturally as "middleware."
  #
  # # Registering an Action
  #
  # The main benefits of registering an action is the ability to retrieve and
  # modify that registered action, as well as easily run the action. An example
  # of registering an action is shown below, with a simple middleware which just
  # outputs to `STDOUT`:
  #
  #     class StdoutMiddleware
  #       def initialize(app, env)
  #         @app = app
  #       end
  #
  #       def call(env)
  #         puts "HI!"
  #         @app.call(env)
  #       end
  #     end
  #
  #     Vagrant::Action.register(:stdout, StdoutMiddleware)
  #
  # Then to run a registered action, assuming `env` is a loaded {Environment}:
  #
  #     env.actions.run(:stdout)
  #
  # Or to retrieve the action class for any reason:
  #
  #     Vagrant::Action[:stdout]
  #
  # # Running an Action
  #
  # There are various built-in registered actions such as `start`, `stop`, `up`,
  # etc. Actions are built to be run in the context of an environment, so use
  # {Environment#actions} to run all actions. Then simply call {#run}:
  #
  #     env.actions.run(:name)
  #
  # Where `:name` is the name of the registered action.
  #
  class Action
    autoload :Environment, 'vagrant/action/environment'
    autoload :Warden,      'vagrant/action/warden'

    include Util
    @@reported_interrupt = false

    class << self
      # Returns the list of registered actions.
      #
      # @return [Array]
      def actions
        @actions ||= {}
      end

      # Registers an action and associates it with a symbol. This
      # symbol can then be referenced in other action builds and
      # callbacks can be registered on that symbol.
      #
      # @param [Symbol] key
      def register(key, callable)
        actions[key.to_sym] = callable
      end

      # Retrieves a registered action by key.
      #
      # @param [Symbol] key
      def [](key)
        actions[key.to_sym]
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
    # Any options given are injected into the environment hash.
    #
    # @param [Object] callable An object which responds to `call`.
    def run(callable_id, options=nil)
      callable = callable_id
      callable = Builder.new.use(callable_id) if callable_id.kind_of?(Class)
      callable = self.class.actions[callable_id] if callable_id.kind_of?(Symbol)
      raise ArgumentError, "Argument to run must be a callable object or registered action." if !callable || !callable.respond_to?(:call)

      action_environment = Action::Environment.new(env)
      action_environment.merge!(options || {})

      # Run the before action run callback, if we're not doing that already
      run(:before_action_run, action_environment) if callable_id != :before_action_run

      # Run the action chain in a busy block, marking the environment as
      # interrupted if a SIGINT occurs, and exiting cleanly once the
      # chain has been run.
      int_callback = lambda do
        if action_environment.interrupted?
          env.ui.error I18n.t("vagrant.actions.runner.exit_immediately")
          abort
        end

        env.ui.warn I18n.t("vagrant.actions.runner.waiting_cleanup") if !@@reported_interrupt
        action_environment.interrupt!
        @@reported_interrupt = true
      end

      # We place a process lock around every action that is called
      env.logger.info "Running action: #{callable_id}"
      env.lock do
        Busy.busy(int_callback) { callable.call(action_environment) }
      end
    end
  end
end
