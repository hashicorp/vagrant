module VagrantPlugins
  module DockerProvider
    module Action
      class Destroy
        def initialize(app, env)
          @app = app
        end

        def call(env)
          machine = env[:machine]

          # If the container actually exists, destroy it
          if machine.state.id != :not_created
            driver  = machine.provider.driver

            # If we have a build image, store that
            image_file = machine.data_dir.join("docker_build_image")
            image      = nil
            if image_file.file?
              image = image_file.read.chomp
            end
            env[:build_image] = image

            env[:ui].info I18n.t("docker_provider.messages.destroying")
            driver.rm(machine.id)
          end

          # Otherwise, always make sure we remove the ID
          machine.id = nil

          @app.call(env)
        end
      end
    end
  end
end
