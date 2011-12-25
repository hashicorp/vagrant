module Vagrant
  module Action
    module Env
      # A middleware which just sets up the environment with some
      # options which are passed to it.
      class Set
        def initialize(app, env, options=nil)
          @app     = app
          @options = options || {}
        end

        def call(env)
          # Merge the options that were given to us
          env.merge!(@options)

          @app.call(env)
        end
      end
    end
  end
end
