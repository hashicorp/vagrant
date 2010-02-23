module Vagrant
  module Actions
    module VM
      class Unpackage < Base
        TAR_OPTIONS = [File::RDONLY, 0644, Tar::GNU]
        attr_accessor :package_file_path

        def initialize(vm, *args)
          super vm
          @package_file_path = args[0]
        end

        def execute!
          # Exit if folder of same name exists
          # TODO provide a way for them to specify the directory name
          error_and_exit(<<-error) if File.exists?(new_base_dir)
The directory `#{file_name_without_extension}` already exists under #{Vagrant.config[:vagrant][:home]}. Please
remove it, rename your packaged VM file, or (TODO) specifiy an
alternate directory
error

          logger.info "Decompressing the packaged VM: #{package_file_path} to: #{working_dir}..."
          decompress

          logger.info "Moving decompressed files in: #{working_dir} to: #{new_base_dir} ..."
          FileUtils.mv(working_dir, new_base_dir)

          #Return the ovf file for importation
          Dir["#{new_base_dir}/*.ovf"].first
        end

        def new_base_dir
          File.join(Vagrant.config.vagrant.home, file_name_without_extension)
        end

        def file_name_without_extension
          File.basename(package_file_path, '.*')
        end

        def working_dir
          package_file_path.chomp(File.extname(package_file_path))
        end

        def package_file_path
          File.expand_path(@package_file_path)
        end

        def decompress
          Tar.open(package_file_path, *TAR_OPTIONS) do |tar|
            tar.extract_all
          end
        end
      end
    end
  end
end
