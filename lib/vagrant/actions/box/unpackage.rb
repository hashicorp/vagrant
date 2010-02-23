module Vagrant
  module Actions
    module Box
      class Unpackage < Base
        TAR_OPTIONS = [File::RDONLY, 0644, Tar::GNU]

        def execute!
          setup_box_dir
          decompress
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
          File.join(Env.boxes_path, @runner.name)
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