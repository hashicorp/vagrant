module Vagrant
  class Action
    module Box
      # Unpackages a downloaded box to a given directory with a given
      # name.
      #
      # # Required Variables
      #
      # * `download.temp_path` - A location for the downloaded box. This is
      #   set by the {Download} action.
      # * `box` - A {Vagrant::Box} object.
      #
      class Unpackage
        attr_reader :box_directory

        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          @env = env

          return if !setup_box_directory
          decompress

          @app.call(@env)

          cleanup if @env.error?
        end

        def cleanup
          if File.directory?(box_directory)
            FileUtils.rm_rf(box_directory)
          end
        end

        def setup_box_directory
          if File.directory?(@env["box"].directory)
            @env.error!(:box_already_exists, :box_name => @env["box"].name)
            return false
          end

          FileUtils.mkdir_p(@env["box"].directory)
          @box_directory = @env["box"].directory
          true
        end

        def decompress
          Dir.chdir(@env["box"].directory) do
            @env.logger.info "Extracting box to #{@env["box"].directory}..."
            Archive::Tar::Minitar.unpack(@env["download.temp_path"], @env["box"].directory)
          end
        end
      end
    end
  end
end
