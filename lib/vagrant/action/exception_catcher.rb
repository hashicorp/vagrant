module Vagrant
  class Action
    # A helper to catch any ActionExceptions raised and to
    # apply the error to the environment.
    module ExceptionCatcher
      def catch_action_exception(env)
        yield env
      rescue ActionException => e
        env.error!(e.key, e.data)
        false
      end
    end
  end
end
