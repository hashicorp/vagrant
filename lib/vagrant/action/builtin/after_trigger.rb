module Vagrant
  module Action
    module Builtin
      # After Trigger
      class AfterTriggerAction
        # @param [Symbol] action_name - The action class name to fire on
        def initialize(app, env, action_name, triggers)
          @app         = app
          @env         = env
          @triggers    = triggers
          @action_name = action_name
        end

        def call(env)
          @triggers.fire_triggers(@action_name, :after, nil, :action) if Vagrant::Util::Experimental.feature_enabled?("typed_triggers");

          # Carry on
          @app.call(env)
        end
      end
    end
  end
end
