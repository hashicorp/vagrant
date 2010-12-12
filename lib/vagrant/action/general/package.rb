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
          @env["package.vagrantfile"] ||= nil
        end

        def call(env)
          @env = env

          raise Errors::PackageOutputExists.new if File.exist?(tar_path)
          raise Errors::PackageRequiresDirectory.new if !@env["package.directory"] || !File.directory?(@env["package.directory"])

          verify_files_to_copy
          compress

          @app.call(env)
        end

        def recover(env)
          # Cleanup any packaged files if the packaging failed at some point.
          File.delete(tar_path) if File.exist?(tar_path)
        end

        def files_to_copy
          package_dir = Pathname.new(@env["package.directory"]).join("include")

          files = @env["package.include"].inject({}) do |acc, file|
            source = Pathname.new(file)
            acc[file] = source.relative? ? package_dir.join(source) : package_dir.join(source.basename)
            acc
          end

          files[@env["package.vagrantfile"]] = package_dir.join("_Vagrantfile") if @env["package.vagrantfile"]
          files
        end

        def verify_files_to_copy
          files_to_copy.each do |file, _|
            raise Errors::PackageIncludeMissing.new(:file => file) if !File.exist?(file)
          end
        end

        # This method copies the include files (passed in via command line)
        # to the temporary directory so they are included in a sub-folder within
        # the actual box
        def copy_include_files
          files_to_copy.each do |from, to|
            @env.ui.info I18n.t("vagrant.actions.general.package.packaging", :file => from)
            FileUtils.mkdir_p(to.parent)
            if FileTest.file?(from)
              FileUtils.cp(from, to)
            else
              FileUtils.cp_r(Dir.glob(from), to.parent)
            end
          end
        end

        # Compress the exported file into a package
        def compress
          @env.ui.info I18n.t("vagrant.actions.general.package.compressing", :tar_path => tar_path)
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
