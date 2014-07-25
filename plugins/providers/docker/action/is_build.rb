module VagrantPlugins
  module DockerProvider
    module Action
      class IsBuild
        def initialize(app, _env)
          @app    = app
        end

        def call(env)
          env[:result] = !!env[:machine].provider_config.build_dir
          @app.call(env)
        end
      end
    end
  end
end
