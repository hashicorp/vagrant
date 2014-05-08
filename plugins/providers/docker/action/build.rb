require "log4r"

module VagrantPlugins
  module DockerProvider
    module Action
      class Build
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant::docker::build")
        end

        def call(env)
          machine   = env[:machine]
          build_dir = env[:build_dir]
          build_dir ||= machine.provider_config.build_dir

          # If we're not building a container, then just skip this step
          return @app.call(env) if !build_dir

          # Try to read the image ID from the cache file if we've
          # already built it.
          image_file = machine.data_dir.join("docker_build_image")
          image      = nil
          if image_file.file?
            image = image_file.read.chomp
          end

          # Verify the image exists if we have one
          if image && !machine.provider.driver.image?(image)
            machine.ui.output(I18n.t("docker_provider.build_image_invalid"))
            image = nil
          end

          # If we have no image or we're rebuilding, we rebuild
          if !image || env[:build_rebuild]
            # Build it
            machine.ui.output(I18n.t("docker_provider.building"))
            image = machine.provider.driver.build(
              build_dir,
              extra_args: machine.provider_config.build_args,
            )
            machine.ui.detail("Image: #{image}")

            # Store the image ID
            image_file.open("w") do |f|
              f.binmode
              f.write("#{image}\n")
            end
          else
            machine.ui.output(I18n.t("docker_provider.already_built"))
          end

          # Set the image for creation
          env[:create_image] = image

          @app.call(env)
        end
      end
    end
  end
end
