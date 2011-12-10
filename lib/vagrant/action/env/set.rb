module Vagrant
  module Action
    module Env
      # A middleware which just sets up the environment with some
      # options which are passed to it.
      class Set
        def initialize(app,env,options=nil)
          @app = app
          env.merge!(options || {})
        end

        def call(env)
          @app.call(env)
        end
      end
    end
  end
end
