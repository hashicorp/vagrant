module Vagrant
  module Action
    module Builtin
      # This middleware simply outputs a message to the UI.
      class Message
        def initialize(app, _env, message, **opts)
          @app     = app
          @message = message
          @opts    = opts
        end

        def call(env)
          unless @opts[:post]
            env[:ui].output(@message)
          end

          @app.call(env)

          if @opts[:post]
            env[:ui].output(@message)
          end
        end
      end
    end
  end
end
