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
            raise ActionException.new(:package_include_file_doesnt_exist, :filename => file) unless File.exists?(file)
          end

          # Get the export action and store a reference to it
          @export_action = @runner.find_action(Export)
          raise ActionException.new(:packaged_requires_export) unless @export_action
        end

        def execute!
          compress
        end

        def tar_path
          File.join(FileUtils.pwd, "#{out_path}#{@runner.env.config.package.extension}")
        end

        def temp_path
          export_action.temp_dir
        end

        def compress
          logger.info "Packaging VM into #{tar_path}..."
          File.open(tar_path, File::CREAT | File::WRONLY, 0644) do |tar|
            Archive::Tar::Minitar::Output.open(tar) do |output|
              begin
                current_dir = FileUtils.pwd

                include_files.each do |f|
                  logger.info "Packaging additional file: #{f}"
                  Archive::Tar::Minitar.pack_file(f, output)
                end

                FileUtils.cd(temp_path)

                Dir.glob(File.join(".", "*")).each do |entry|
                  Archive::Tar::Minitar.pack_file(entry, output)
                end
              ensure
                FileUtils.cd(current_dir)
              end
            end
          end
        end
      end
    end
  end
end
