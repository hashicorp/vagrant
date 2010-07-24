module Vagrant
  class Action
    module VM
      class Package
        include Util

        def initialize(app, env)
          @app = app
          @env = env
          @env["package.output"] ||= env["config"].package.name
          @env["package.include"] ||= []

          env.error!(:box_file_exists, :output_file => tar_path) if File.exist?(tar_path)
        end

        def call(env)
          @env = env

          return env.error!(:package_requires_export) if !@env["export.temp_dir"]
          return if !verify_included_files
          compress

          @app.call(env)

          cleanup if env.error?
        end

        def cleanup
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
            include_dir = File.join(@env["export.temp_dir"], "include")
            FileUtils.mkdir_p(include_dir)

            @env["package.include"].each do |f|
              @env.logger.info "Packaging additional file: #{f}"
              FileUtils.cp(f, include_dir)
            end
          end
        end

        # This method creates the auto-generated Vagrantfile at the root of the
        # box. This Vagrantfile contains the MAC address so that the user doesn't
        # have to worry about it.
        def create_vagrantfile
          File.open(File.join(@env["export.temp_dir"], "Vagrantfile"), "w") do |f|
            f.write(TemplateRenderer.render("package_Vagrantfile", {
              :base_mac => @env["vm"].vm.network_adapters.first.mac_address
            }))
          end
        end

        # Compress the exported file into a package
        def compress
          @env.logger.info "Packaging VM into #{tar_path}..."
          File.open(tar_path, Platform.tar_file_options) do |tar|
            Archive::Tar::Minitar::Output.open(tar) do |output|
              begin
                current_dir = FileUtils.pwd

                copy_include_files
                create_vagrantfile

                FileUtils.cd(@env["export.temp_dir"])
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
