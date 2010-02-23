module Vagrant
  module Actions
    module Box
      # An action which acts on a box by downloading the box file from
      # the given URI into a temporary location.
      class Download < Base
        BASENAME = "box"
        BUFFERSIZE = 1048576 # 1 MB

        def execute!
          with_tempfile do |tempfile|
            copy_uri_to(tempfile)
          end
        end

        def with_tempfile
          logger.info "Creating tempfile for storing box file..."
          Tempfile.open(BASENAME, Env.tmp_path) do |tempfile|
            yield tempfile
          end
        end

        def copy_uri_to(f)
          logger.info "Copying box to temporary location..."
          open(@runner.uri) do |remote_file|
            loop do
              break if remote_file.eof?
              f.write(remote_file.read(BUFFERSIZE))
            end
          end
        end
      end
    end
  end
end