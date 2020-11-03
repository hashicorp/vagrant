require 'log4r'

require 'vagrant/action/hook'
require 'vagrant/util/busy'
require 'vagrant/util/experimental'

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

        # NOTE: Triggers are initialized later in the Action::Runer because of
        # how `@lazy_globals` are evaluated. Rather than trying to guess where
        # the `env` is coming from, we can wait until they're merged into a single
        # hash above.
        env = environment[:env]
        machine = environment[:machine]

        environment[:triggers] = machine.triggers if machine

        if env
          ui = Vagrant::UI::Prefixed.new(env.ui, "vagrant")
          environment[:triggers] ||= Vagrant::Plugin::V2::Trigger.
            new(env, env.vagrantfile.config.trigger, machine, ui)
        end

        # Run the action chain in a busy block, marking the environment as
        # interrupted if a SIGINT occurs, and exiting cleanly once the
        # chain has been run.
        ui = environment[:ui] if environment.key?(:ui)
        int_callback = lambda do
          if environment[:interrupted]
            if ui
              begin
                ui.error I18n.t("vagrant.actions.runner.exit_immediately")
              rescue ThreadError
                # We're being called in a trap-context. Wrap in a thread.
                Thread.new {
                  ui.error I18n.t("vagrant.actions.runner.exit_immediately")
                }.join(THREAD_MAX_JOIN_TIMEOUT)
              end
            end
            abort
          end

          if ui && !@@reported_interrupt
            begin
              ui.warn I18n.t("vagrant.actions.runner.waiting_cleanup")
            rescue ThreadError
              # We're being called in a trap-context. Wrap in a thread.
              Thread.new {
                ui.warn I18n.t("vagrant.actions.runner.waiting_cleanup")
              }.join(THREAD_MAX_JOIN_TIMEOUT)
            end
          end
          environment[:interrupted] = true
          @@reported_interrupt = true
        end

        action_name = environment[:action_name]

        # We place a process lock around every action that is called
        @logger.info("Running action: #{action_name} #{callable_id}")
        Util::Busy.busy(int_callback) { callable.call(environment) }

        # Return the environment in case there are things in there that
        # the caller wants to use.
        environment
      end
    end
  end
end
