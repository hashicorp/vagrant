require 'fileutils'
require "pathname"

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
          env["package.output"] ||= "package.box"
        end

        def call(env)
          @env = env
          file_name = File.basename(@env["package.output"].to_s)
          
          raise Errors::PackageOutputDirectory if File.directory?(tar_path)
          raise Errors::PackageOutputExists, file_name:file_name if File.exist?(tar_path)
          raise Errors::PackageRequiresDirectory if !env["package.directory"] ||
            !File.directory?(env["package.directory"])

          @app.call(env)

          @env[:ui].info I18n.t("vagrant.actions.general.package.compressing", tar_path: tar_path)
          copy_include_files
          setup_private_key
          compress
        end

        def recover(env)
          @env = env

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

            @env[:ui].info I18n.t("vagrant.actions.general.package.packaging", file: from)
            FileUtils.mkdir_p(to.parent)

            # Copy direcotry contents recursively.
            if File.directory?(from)
              FileUtils.cp_r(Dir.glob(from), to.parent, preserve: true)
            else
              FileUtils.cp(from, to, preserve: true)
            end
          end
        rescue Errno::EEXIST => e
          raise if !e.to_s.include?("symlink")

          # The directory contains symlinks. Show a nicer error.
          raise Errors::PackageIncludeSymlink
        end

        # Compress the exported file into a package
        def compress
          # Get the output path. We have to do this up here so that the
          # pwd returns the proper thing.
          output_path = tar_path.to_s

          # Switch into that directory and package everything up
          Util::SafeChdir.safe_chdir(@env["package.directory"]) do
            # Find all the files in our current directory and tar it up!
            files = Dir.glob(File.join(".", "*"))

            # Package!
            Util::Subprocess.execute("bsdtar", "-czf", output_path, *files)
          end
        end

        # This will copy the generated private key into the box and use
        # it for SSH by default. We have to do this because we now generate
        # random keypairs on boot, so packaged boxes would stop working
        # without this.
        def setup_private_key
          # If we don't have machine, we do nothing (weird)
          return if !@env[:machine]

          # If we don't have a data dir, we also do nothing (base package)
          return if !@env[:machine].data_dir

          # If we don't have a generated private key, we do nothing
          path = @env[:machine].data_dir.join("private_key")
          return if !path.file?

          # Copy it into our box directory
          dir = Pathname.new(@env["package.directory"])
          new_path = dir.join("vagrant_private_key")
          FileUtils.cp(path, new_path)

          # Append it to the Vagrantfile (or create a Vagrantfile)
          vf_path = dir.join("Vagrantfile")
          mode = "w+"
          mode = "a" if vf_path.file?
          vf_path.open(mode) do |f|
            f.binmode
            f.puts
            f.puts %Q[Vagrant.configure("2") do |config|]
            f.puts %Q[  config.ssh.private_key_path = File.expand_path("../vagrant_private_key", __FILE__)]
            f.puts %Q[end]
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
