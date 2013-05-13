require 'fileutils'

require 'vagrant/util/safe_chdir'
require 'vagrant/util/subprocess'

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
          env["package.output"] ||= env[:global_config].package.name
        end

        def call(env)
          @env = env

          raise Errors::PackageOutputDirectory if File.directory?(tar_path)
          raise Errors::PackageOutputExists if File.exist?(tar_path)
          raise Errors::PackageRequiresDirectory if !env["package.directory"] ||
            !File.directory?(env["package.directory"])

          compress

          @app.call(env)
        end

        def recover(env)
          # There are certain exceptions that we don't delete the file for.
          ignore_exc = [Errors::PackageOutputDirectory, Errors::PackageOutputExists]
          ignore_exc.each do |exc|
            return if env["vagrant.error"].is_a?(exc)
          end

          # Cleanup any packaged files if the packaging failed at some point.
          File.delete(tar_path) if File.exist?(tar_path)
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
              FileUtils.cp_r(Dir.glob(from), to.parent, :preserve => true)
            else
              FileUtils.cp(from, to, :preserve => true)
            end
          end
        end

        # Compress the exported file into a package
        def compress
          @env[:ui].info I18n.t("vagrant.actions.general.package.compressing", :tar_path => tar_path)

          # Copy over the included files
          copy_include_files

          # Get the output path. We have to do this up here so that the
          # pwd returns the proper thing.
          output_path = tar_path.to_s

          # Switch into that directory and package everything up
          Util::SafeChdir.safe_chdir(@env["package.directory"]) do
            # Find all the files in our current directory and tar it up!
            files = Dir.glob(File.join(".", "**", "*"))

            # Package!
            Util::Subprocess.execute("bsdtar", "-czf", output_path, *files)
          end
        end

        # Path to the final box output file
        def tar_path
          File.expand_path(@env["package.output"], FileUtils.pwd)
        end
      end
    end
  end
end
