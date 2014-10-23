module VagrantPlugins
  module DockerProvider
    module Action
      class InitState
        def initialize(app, env)
          @app = app
        end

        def call(env)
          # We set the ID of the machine to "preparing" so that we can use
          # the data dir without it being deleted with the not_created state.
          env[:machine].id = nil
          env[:machine].id = "preparing"

          @app.call(env)
        end
      end
    end
  end
end
