module Vagrant
  class Action
    module Box
      class Destroy
        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          env.logger.info "Deleting box directory..."
          FileUtils.rm_rf(env["box"].directory)

          @app.call(env)
        end
      end
    end
  end
end
