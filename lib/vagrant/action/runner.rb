require 'log4r'

require 'vagrant/util/busy'

# TODO:
# * env.ui
# * env.lock

module Vagrant
  class Action
    class Runner
      @@reported_interrupt = false

      def initialize(registry)
        @registry = registry
        @logger   = Log4r::Logger.new("vagrant::action::runner")
      end

      def run(callable_id, options=nil)
        callable = callable_id
        callable = Builder.new.use(callable_id) if callable_id.kind_of?(Class)
        callable = @registry.get(callable_id) if callable_id.kind_of?(Symbol)
        raise ArgumentError, "Argument to run must be a callable object or registered action." if !callable || !callable.respond_to?(:call)

        # Create the initial environment with the options given
        environment = Environment.new
        environment.merge!(options || {})

        # Run the action chain in a busy block, marking the environment as
        # interrupted if a SIGINT occurs, and exiting cleanly once the
        # chain has been run.
        int_callback = lambda do
          if environment.interrupted?
            env.ui.error I18n.t("vagrant.actions.runner.exit_immediately")
            abort
          end

          env.ui.warn I18n.t("vagrant.actions.runner.waiting_cleanup") if !@@reported_interrupt
          environment.interrupt!
          @@reported_interrupt = true
        end

        # We place a process lock around every action that is called
        @logger.info("Running action: #{callable_id}")
        Util::Busy.busy(int_callback) { callable.call(environment) }
      end
    end
  end
end
