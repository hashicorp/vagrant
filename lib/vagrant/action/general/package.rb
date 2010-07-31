module Vagrant
  class Action
    module General
      # A general packaging (tar) middleware. Given the following options,
      # it will do the right thing:
      #
      #   * package.output - The filename of the outputted package.
      #   * package.include - An array of files to include in the package.
      #   * package.directory - The directory which contains the contents to
      #       compress into the package.
      #
      # This middleware always produces the final file in the current working
      # directory (FileUtils.pwd)
      class Package
        include Util

        def initialize(app, env)
          @app = app
          @env = env
          @env["package.output"] ||= env["config"].package.name
          @env["package.include"] ||= []
        end

        def call(env)
          @env = env

          return env.error!(:package_output_exists) if File.exist?(tar_path)
          return env.error!(:package_requires_directory) if !@env["package.directory"] || !File.directory?(@env["package.directory"])
          return if !verify_included_files
          compress

          @app.call(env)
        end

        def rescue(env)
          # Cleanup any packaged files if the packaging failed at some point.
          File.delete(tar_path) if File.exist?(tar_path)
        end

        def verify_included_files
          @env["package.include"].each do |file|
            if !File.exist?(file)
              @env.error!(:package_include_file_doesnt_exist, :filename => file)
              return false
            end
          end

          true
        end

        # This method copies the include files (passed in via command line)
        # to the temporary directory so they are included in a sub-folder within
        # the actual box
        def copy_include_files
          if @env["package.include"].length > 0
            include_dir = File.join(@env["package.directory"], "include")
            FileUtils.mkdir_p(include_dir)

            @env["package.include"].each do |f|
              @env.logger.info "Packaging additional file: #{f}"
              FileUtils.cp(f, include_dir)
            end
          end
        end

        # Compress the exported file into a package
        def compress
          @env.logger.info "Compressing package to #{tar_path}..."
          File.open(tar_path, Platform.tar_file_options) do |tar|
            Archive::Tar::Minitar::Output.open(tar) do |output|
              begin
                current_dir = FileUtils.pwd

                copy_include_files

                FileUtils.cd(@env["package.directory"])
                Dir.glob(File.join(".", "**", "*")).each do |entry|
                  Archive::Tar::Minitar.pack_file(entry, output)
                end
              ensure
                FileUtils.cd(current_dir)
              end
            end
          end
        end

        # Path to the final box output file
        def tar_path
          File.join(FileUtils.pwd, @env["package.output"])
        end
      end
    end
  end
end
