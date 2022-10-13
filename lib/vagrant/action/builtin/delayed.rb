module Vagrant
  module Action
    module Builtin
      # This class is used to delay execution until the end of
      # a configured stack
      class Delayed
        # @param [Object] callable The object to call (must respond to #call)
        def initialize(app, env, callable)
          if !callable.respond_to?(:call)
            raise TypeError, "Callable argument is expected to respond to `#call`"
          end
          @app         = app
          @env         = env
          @callable    = callable
        end

        def call(env)
          # Allow the rest of the call stack to execute
          @app.call(env)
          # Now call our delayed stack
          @callable.call(env)
        end
      end
    end
  end
end
