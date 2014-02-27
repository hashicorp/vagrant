module Vagrant
  module Action
    module Builtin
      # This middleware simply outputs a message to the UI.
      class Message
        def initialize(app, env, message, **opts)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::action::builtin::is_state")
          @message  = message
        end

        def call(env)
          env[:ui].output(@message)
          @app.call(env)
        end
      end
    end
  end
end
