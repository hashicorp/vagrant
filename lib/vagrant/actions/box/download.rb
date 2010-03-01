module Vagrant
  module Actions
    module Box
      # An action which acts on a box by downloading the box file from
      # the given URI into a temporary location.
      class Download < Base
        BASENAME = "box"
        BUFFERSIZE = 1048576 # 1 MB

        attr_reader :downloader

        def prepare
          # Parse the URI given and prepare a downloader
          uri = URI.parse(@runner.uri)

          if uri.is_a?(URI::Generic)
            logger.info "Generic URI type for box download, assuming file..."
            @downloader = Downloaders::File.new
          end

          raise ActionException.new("Unknown URI type for box download.") unless @downloader
        end

        def execute!
          with_tempfile do |tempfile|
            download_to(tempfile)
            @runner.temp_path = tempfile.path
          end
        end

        def after_unpackage
          logger.info "Cleaning up tempfile..."
          File.unlink(@runner.temp_path) if @runner.temp_path && File.exist?(@runner.temp_path)
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