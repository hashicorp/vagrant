require "log4r"

module VagrantPlugins
  module DockerProvider
    module Action
      class DestroyBuildImage
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant::docker::destroybuildimage")
        end

        def call(env)
          machine   = env[:machine]

          # Try to read the image ID from the cache file if we've
          # already built it.
          image_file = machine.data_dir.join("docker_build_image")
          image      = nil
          if image_file.file?
            image = image_file.read.chomp

            machine.ui.output(I18n.t("docker_provider.build_image_destroy"))
            machine.provider.driver.rmi(image)
            image_file.delete
          end

          @app.call(env)
        end
      end
    end
  end
end
