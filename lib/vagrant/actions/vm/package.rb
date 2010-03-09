module Vagrant
  module Actions
    module VM
      class Package < Base
        attr_accessor :out_path
        attr_accessor :include_files
        attr_reader :export_action

        def initialize(vm, out_path = nil, include_files = nil, *args)
          super
          @out_path = out_path || "package"
          @include_files = include_files || []
          @temp_path = nil
        end

        def prepare
          # Verify the existance of all the additional files, if any
          @include_files.each do |file|
            raise ActionException.new("#{file} does not exist") unless File.exists?(file)
          end

          # Get the export action and store a reference to it
          @export_action = @runner.find_action(Export)
          raise ActionException.new("Package must be used in conjunction with export.") unless @export_action
        end

        def execute!
          compress
        end

        def tar_path
          File.join(FileUtils.pwd, "#{out_path}#{Vagrant.config.package.extension}")
        end

        def temp_path
          export_action.temp_dir
        end

        def compress
          logger.info "Packaging VM into #{tar_path} ..."
          open(tar_path, File::CREAT | File::WRONLY, 0644) do |tar|
            begin
              current_dir = FileUtils.pwd
              @include_files.each do |f|
                logger.info "Packaging additional file: #{f}"
                Archive::Tar::Minitar.pack(f, tar)
              end

              FileUtils.cd(temp_path)

              # Append tree will append the entire directory tree unless a relative folder reference is used
              Archive::Tar::Minitar.pack(".", tar)
            ensure
              FileUtils.cd(current_dir)
            end
          end
        end
      end
    end
  end
end
