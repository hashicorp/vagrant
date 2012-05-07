require 'log4r'

require 'vagrant/util/busy'

# TODO:
# * env.lock

module Vagrant
  module Action
    class Runner
      @@reported_interrupt = false

      def initialize(registry, globals=nil, &block)
        @registry     = registry
        @globals      = globals || {}
        @lazy_globals = block
        @logger       = Log4r::Logger.new("vagrant::action::runner")
      end

      def run(callable_id, options=nil)
        callable = callable_id
        callable = Builder.new.use(callable_id) if callable_id.kind_of?(Class)
        callable = registry_sequence(callable_id) if callable_id.kind_of?(Symbol)
        raise ArgumentError, "Argument to run must be a callable object or registered action." if !callable || !callable.respond_to?(:call)

        # Create the initial environment with the options given
        environment = Environment.new
        environment.merge!(@globals)
        environment.merge!(@lazy_globals.call) if @lazy_globals
        environment.merge!(options || {})

        # Run the action chain in a busy block, marking the environment as
        # interrupted if a SIGINT occurs, and exiting cleanly once the
        # chain has been run.
        ui = environment[:ui] if environment.has_key?(:ui)
        int_callback = lambda do
          if environment[:interrupted]
            ui.error I18n.t("vagrant.actions.runner.exit_immediately") if ui
            abort
          end

          ui.warn I18n.t("vagrant.actions.runner.waiting_cleanup") if ui && !@@reported_interrupt
          environment[:interrupted] = true
          @@reported_interrupt = true
        end

        # We place a process lock around every action that is called
        @logger.info("Running action: #{callable_id}")
        Util::Busy.busy(int_callback) { callable.call(environment) }
      end

      protected

      def registry_sequence(id)
        # Attempt to get the sequence
        seq = @registry.get(id)
        return nil if !seq

        # Go through all the registered plugins and get all the hooks
        # for this sequence.
        Vagrant.plugin("1").registered.each do |plugin|
          hooks  = plugin.action_hook(Vagrant::Plugin::V1::ALL_ACTIONS)
          hooks += plugin.action_hook(id)

          hooks.each do |hook|
            hook.call(seq)
          end
        end

        # Return the sequence
        seq
      end
    end
  end
end
