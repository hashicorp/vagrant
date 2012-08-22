module Vagrant
  module Action
    module Builtin
      # This middleware class allows you to modify the environment hash
      # in the middle of a middleware sequence. The new environmental data
      # will take affect at this stage in the middleware and will persist
      # through.
      class EnvSet
        def initialize(app, env, new_env=nil)
          @app     = app
          @new_env = new_env || {}
        end

        def call(env)
          # Merge in the new data
          env.merge!(@new_env)

          # Carry on
          @app.call(env)
        end
      end
    end
  end
end
