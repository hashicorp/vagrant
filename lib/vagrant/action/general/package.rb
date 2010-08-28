require 'fileutils'
require 'archive/tar/minitar'

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

          raise Errors::PackageOutputExists.new if File.exist?(tar_path)
          raise Errors::PackageRequiresDirectory.new if !@env["package.directory"] || !File.directory?(@env["package.directory"])

          verify_included_files
          compress

          @app.call(env)
        end

        def recover(env)
          # Cleanup any packaged files if the packaging failed at some point.
          File.delete(tar_path) if File.exist?(tar_path)
        end

        def verify_included_files
          @env["package.include"].each do |file|
            raise Errors::PackageIncludeMissing.new(:file => file) if !File.exist?(file)
          end
        end

        # This method copies the include files (passed in via command line)
        # to the temporary directory so they are included in a sub-folder within
        # the actual box
        def copy_include_files
          if @env["package.include"].length > 0
            include_dir = File.join(@env["package.directory"], "include")
            FileUtils.mkdir_p(include_dir)

            @env["package.include"].each do |f|
              @env.ui.info "vagrant.actions.general.package.packaging", :file => f
              FileUtils.cp(f, include_dir)
            end
          end
        end

        # Compress the exported file into a package
        def compress
          @env.ui.info "vagrant.actions.general.package.compressing", :tar_path => tar_path
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
