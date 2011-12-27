require 'fileutils'
require 'archive/tar/minitar'

module Vagrant
  module Action
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

          env["package.files"]  ||= {}
          env["package.output"] ||= env["global_config"].package.name
        end

        def call(env)
          @env = env

          raise Errors::PackageOutputExists if File.exist?(tar_path)
          raise Errors::PackageRequiresDirectory if !env["package.directory"] ||
            !File.directory?(env["package.directory"])

          compress

          @app.call(env)
        end

        def recover(env)
          # Don't delete the tar_path if the error is that the output already
          # exists, since this will nuke the user's previous file.
          if !env["vagrant.error"].is_a?(Errors::PackageOutputExists)
						# Cleanup any packaged files if the packaging failed at some point.
						File.delete(tar_path) if File.exist?(tar_path)
					end
        end

        # This method copies the include files (passed in via command line)
        # to the temporary directory so they are included in a sub-folder within
        # the actual box
        def copy_include_files
          include_directory = Pathname.new(@env["package.directory"]).join("include")

          @env["package.files"].each do |from, dest|
            # We place the file in the include directory
            to = include_directory.join(dest)

            @env[:ui].info I18n.t("vagrant.actions.general.package.packaging", :file => from)
            FileUtils.mkdir_p(to.parent)

            # Copy direcotry contents recursively.
            if File.directory?(from)
              FileUtils.cp_r(Dir.glob(from), to.parent)
            else
              FileUtils.cp(from, to)
            end
          end
        end

        # Compress the exported file into a package
        def compress
          @env[:ui].info I18n.t("vagrant.actions.general.package.compressing", :tar_path => tar_path)
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
