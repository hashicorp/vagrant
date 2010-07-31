module Vagrant
  class Action
    module Box
      class Download
        BASENAME = "box"

        include Util

        attr_reader :temp_path

        def initialize(app, env)
          @app = app
          @env = env
          @env["download.classes"] ||= []
          @env["download.classes"] += [Downloaders::HTTP, Downloaders::File]
        end

        def call(env)
          @env = env

          download if instantiate_downloader
          return if env.error?

          @app.call(@env)
          
          recover(env) # called in both cases to cleanup workspace
        end
 
        def instantiate_downloader
          @env["download.classes"].each do |klass|
            if klass.match?(@env["box"].uri)
              @env.logger.info "Downloading with #{klass}..."
              @downloader = klass.new(@env)
            end
          end

          if !@downloader
            @env.error!(:box_download_unknown_type)
            return false
          end

          @downloader.prepare(@env["box"].uri)
          true
        end

        def download
          with_tempfile do |tempfile|
            download_to(tempfile)
            @temp_path = @env["download.temp_path"] = tempfile.path
          end
        end

        def recover(env)
          if temp_path && File.exist?(temp_path)
            env.logger.info "Cleaning up downloaded box..."
            File.unlink(temp_path)
          end
        end

        def with_tempfile
          @env.logger.info "Creating tempfile for storing box file..."
          File.open(box_temp_path, Platform.tar_file_options) do |tempfile|
            yield tempfile
          end
        end

        def box_temp_path
          File.join(@env.env.tmp_path, BASENAME + Time.now.to_i.to_s)
        end

        def download_to(f)
          @env.logger.info "Copying box to temporary location..."
          @downloader.download!(@env["box"].uri, f)
        end
      end
    end
  end
end
