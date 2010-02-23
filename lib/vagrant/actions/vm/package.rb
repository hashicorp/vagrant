module Vagrant
  module Actions
    module VM
      class Package < Base
        attr_accessor :name, :to

        def initialize(vm, *args)
          super vm
          @name = args[0]
          @to = args[1]
        end

        def execute!
          logger.info "Packaging VM into #{tar_path} ..."
          compress

          logger.info "Removing working directory ..."
          clean

          tar_path
        end

        def clean
          FileUtils.rm_r(working_dir)
        end

        def working_dir
          FileUtils.mkpath(File.join(@to, @name))
        end

        def tar_path
          "#{working_dir}#{Vagrant.config.package.extension}"
        end

        def compress
          Tar.open(tar_path, File::CREAT | File::WRONLY, 0644, Tar::GNU) do |tar|
            begin
              # Append tree will append the entire directory tree unless a relative folder reference is used
              current_dir = FileUtils.pwd
              FileUtils.cd(@to)
              tar.append_tree(@name)
            ensure
              FileUtils.cd(current_dir)
            end
          end
        end
      end
    end
  end
end
