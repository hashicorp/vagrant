module Vagrant
  module Actions
    module VM
      class Package < Base
        attr_accessor :out_path
        attr_accessor :include_files
        attr_accessor :temp_path

        def initialize(vm, out_path = nil, include_files = nil, *args)
          super
          @out_path = out_path || "package"
          @include_files = include_files || []
          @temp_path = nil
        end

        def prepare 
          @include_files.each do |file|
            raise ActionException.new("#{file} does not exist") unless File.exists?(file)
          end
        end

        def execute!
          compress
          clean
        end

        def clean
          logger.info "Removing temporary directory ..."
          FileUtils.rm_r(temp_path)
        end

        def tar_path
          File.join(FileUtils.pwd, "#{out_path}#{Vagrant.config.package.extension}")
        end

        def compress
          logger.info "Packaging VM into #{tar_path} ..."
          Tar.open(tar_path, File::CREAT | File::WRONLY, 0644, Tar::GNU) do |tar|
            begin
              current_dir = FileUtils.pwd
              @include_files.each do |f|
                logger.info "Packaging additional file: #{f}"
                tar.append_file(f)
              end

              FileUtils.cd(temp_path)

              # Append tree will append the entire directory tree unless a relative folder reference is used
              tar.append_tree(".")
            ensure
              FileUtils.cd(current_dir)
            end
          end
        end

        # This is a callback by Actions::VM::Export
        def set_export_temp_path(temp_path)
          @temp_path = temp_path
        end
      end
    end
  end
end
