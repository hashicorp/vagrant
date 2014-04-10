module VagrantPlugins
  module DockerProvider
    module Action
      # This action is responsible for creating the host machine if
      # we need to.
      class HostMachine
        def initialize(app, env)
          @app = app
        end

        def call(env)
          @app.call(env)
        end
      end
    end
  end
end
