module Vagrant
  module Actions
    module Box
      # An action which acts on a box by downloading the box file from
      # the given URI into a temporary location. This action parses a
      # given URI and handles downloading it via one of the many Vagrant
      # downloads (such as {Vagrant::Downloaders::File}).
      #
      # This action cleans itself up by removing the downloaded box file.
      class Download < Base
        BASENAME = "box"
        BUFFERSIZE = 1048576 # 1 MB

        attr_reader :downloader

        def prepare
          # Parse the URI given and prepare a downloader
          uri = URI.parse(@runner.uri)
          uri_map = [[URI::HTTP, Downloaders::HTTP], [URI::Generic, Downloaders::File]]

          uri_map.find do |uri_type, downloader_klass|
            if uri.is_a?(uri_type)
              logger.info "#{uri_type} for URI, downloading via #{downloader_klass}..."
              @downloader = downloader_klass.new
            end
          end

          raise ActionException.new("Unknown URI type for box download.") unless @downloader

          # Prepare the downloader
          @downloader.prepare(@runner.uri)
        end

        def execute!
          with_tempfile do |tempfile|
            download_to(tempfile)
            @runner.temp_path = tempfile.path
          end
        end

        def cleanup
          if @runner.temp_path && File.exist?(@runner.temp_path)
            logger.info "Cleaning up downloaded box..."
            File.unlink(@runner.temp_path)
          end
        end

        def rescue(exception)
          cleanup
        end

        def with_tempfile
          logger.info "Creating tempfile for storing box file..."
          Tempfile.open(BASENAME, Env.tmp_path) do |tempfile|
            yield tempfile
          end
        end

        def download_to(f)
          logger.info "Copying box to temporary location..."
          downloader.download!(@runner.uri, f)
        end
      end
    end
  end
end