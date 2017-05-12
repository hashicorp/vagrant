module VagrantPlugins
  module DockerProvider
    module Action
      class IsBuild
        def initialize(app, env)
          @app    = app
        end

        def call(env)
          env[:result] = (!!env[:machine].provider_config.build_dir || !!env[:machine].provider_config.git_repo)
          @app.call(env)
        end
      end
    end
  end
end
