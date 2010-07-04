module Vagrant
  class Action
    # A middleware which simply halts if the environment is erroneous.
    class ErrorHalt
      def initialize(app,env)
        @app = app
      end

      def call(env)
        @app.call(env) if !env.error?
      end
    end
  end
end
