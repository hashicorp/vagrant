module Vagrant
  module Action
    module Builtin
      # This middleware simply outputs a message to the UI.
      class Message
        def initialize(app, env, message, **opts)
          @app     = app
          @message = message
        end

        def call(env)
          env[:ui].output(@message)
          @app.call(env)
        end
      end
    end
  end
end
