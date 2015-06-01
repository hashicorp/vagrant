require 'log4r'

require 'vagrant/action/hook'
require 'vagrant/util/busy'

module Vagrant
  module Action
    class Runner
      @@reported_interrupt = false

      def initialize(globals=nil, &block)
        @globals      = globals || {}
        @lazy_globals = block
        @logger       = Log4r::Logger.new("vagrant::action::runner")
      end

      def run(callable_id, options=nil)
        callable = callable_id
        if !callable.kind_of?(Builder)
          if callable_id.kind_of?(Class) || callable_id.respond_to?(:call)
            callable = Builder.build(callable_id)
          end
        end

        if !callable || !callable.respond_to?(:call)
          raise ArgumentError,
            "Argument to run must be a callable object or registered action."
        end

        # Create the initial environment with the options given
        environment = {}
        environment.merge!(@globals)
        environment.merge!(@lazy_globals.call) if @lazy_globals
        environment.merge!(options || {})

        # Setup the action hooks
        hooks = Vagrant.plugin("2").manager.action_hooks(environment[:action_name])
        if !hooks.empty?
          @logger.info("Preparing hooks for middleware sequence...")
          environment[:action_hooks] = hooks.map do |hook_proc|
            Hook.new.tap do |h|
              hook_proc.call(h)
            end
          end

          @logger.info("#{environment[:action_hooks].length} hooks defined.")
        end

        # Run the action chain in a busy block, marking the environment as
        # interrupted if a SIGINT occurs, and exiting cleanly once the
        # chain has been run.
        ui = environment[:ui] if environment.key?(:ui)
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
        @logger.info("Running action: #{environment[:action_name]} #{callable_id}")
        Util::Busy.busy(int_callback) { callable.call(environment) }

        # Return the environment in case there are things in there that
        # the caller wants to use.
        environment
      end
    end
  end
end
