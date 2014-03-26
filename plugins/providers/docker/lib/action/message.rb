module VagrantPlugins
  module DockerProvider
    module Action
      # XXX: Is this really needed? Should we contribute this back to Vagrant's core?
      class Message
        def initialize(app, env, msg_key, type = :info)
          @app     = app
          @msg_key = msg_key
          @type    = type
        end

        def call(env)
          machine = env[:machine]
          message = I18n.t("docker_provider.messages.#{@msg_key}", name: machine.name)

          env[:ui].send @type, message

          @app.call env
        end
      end
    end
  end
end
