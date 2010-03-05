module Vagrant
  module Actions
    module Box
      # This action unpackages a downloaded box file into its final
      # box destination within the vagrant home folder.
      class Unpackage < Base
        TAR_OPTIONS = [File::RDONLY, 0644, Tar::GNU]

        def execute!
          @runner.invoke_around_callback(:unpackage) do
            setup_box_dir
            decompress
          end
        end

        def rescue(exception)
          if File.directory?(box_dir)
            logger.info "An error occurred, rolling back box unpackaging..."
            FileUtils.rm_rf(box_dir)
          end
        end

        def setup_box_dir
          if File.directory?(box_dir)
            error_and_exit(<<-msg)
This box appears to already exist! Please call `vagrant box remove #{@runner.name}`
and then try to add it again.
msg
          end

          FileUtils.mkdir_p(box_dir)
        end

        def box_dir
          @runner.directory
        end

        def decompress
          Dir.chdir(box_dir) do
            logger.info "Extracting box to #{box_dir}..."
            Tar.open(@runner.temp_path, *TAR_OPTIONS) do |tar|
              tar.extract_all
            end
          end
        end
      end
    end
  end
end