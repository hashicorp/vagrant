module Vagrant
  module Action
    module Builtin
      # This class is intended to be used by the Action::Warden class for executing
      # action triggers before any given action.
      class BeforeTriggerAction
        # @param [Symbol] action_name - The action class name to fire trigger on
        # @param [Vagrant::Plugin::V2::Triger] triggers - trigger object
        def initialize(app, env, action_name, triggers)
          @app         = app
          @env         = env
          @triggers    = triggers
          @action_name = action_name
        end

        def call(env)
          machine = env[:machine]
          machine_name = machine.name if machine

          @triggers.fire_triggers(@action_name, :before, machine_name, :action) if Vagrant::Util::Experimental.feature_enabled?("typed_triggers");

          # Carry on
          @app.call(env)
        end
      end
    end
  end
end
