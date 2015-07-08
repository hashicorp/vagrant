module VagrantPlugins
  module DockerProvider
    module Action
      class Pull
        def initialize(app, env)
          @app = app
        end

        def call(env)
          @env             = env
          @machine         = env[:machine]
          @provider_config = @machine.provider_config
          @driver          = @machine.provider.driver

          image = @env[:create_image]
          image ||= @provider_config.image

          env[:ui].output(I18n.t("docker_provider.pull", image: image))
          @driver.pull(image)

          @app.call(env)
        end
      end
    end
  end
end
