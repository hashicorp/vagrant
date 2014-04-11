module Vagrant
  module Action
    module Builtin
      # This middleware class allows a sort of "conditional" run within
      # a single middlware sequence. It takes another middleware runnable,
      # runs it with the same environment, then yields the resulting env to a block,
      # allowing that block to determine the next course of action in the
      # middleware sequence.
      #
      # The first argument to this middleware sequence is anywhere middleware
      # runnable, whether it be a class, lambda, or something else that
      # responds to `call`. This middleware runnable is run with the same
      # environment as this class.
      #
      # After running, {Call} takes the environment and yields it to a block
      # given to initialize the class, along with an instance of {Builder}.
      # The result is used to build up a new sequence on the given builder.
      # This builder is then run.
      class Call
        # For documentation, read the description of the {Call} class.
        #
        # @param [Object] callable A valid middleware runnable object. This
        #   can be a class, a lambda, or an object that responds to `call`.
        # @yield [result, builder] This block is expected to build on `builder`
        #   which is the next middleware sequence that will be run.
        def initialize(app, env, callable, *callable_args, &block)
          raise ArgumentError, "A block must be given to Call" if !block

          @app      = app
          @callable = callable
          @callable_args = callable_args
          @block    = block
          @child_app = nil
        end

        def call(env)
          runner  = Runner.new

          # Build the callable that we'll run
          callable = Builder.build(@callable, *@callable_args)

          # Run our callable with our environment
          new_env = runner.run(callable, env)

          # Build our new builder based on the result
          builder = Builder.new
          @block.call(new_env, builder)

          # Append our own app onto the builder so we slide the new
          # stack into our own chain...
          builder.use @app
          @child_app = builder.to_app(new_env)
          final_env  = runner.run(@child_app, new_env)

          # Merge the environment into our original environment
          env.merge!(final_env)
        end

        def recover(env)
          # Call back into our compiled application and recover it.
          @child_app.recover(env) if @child_app
        end
      end
    end
  end
end
