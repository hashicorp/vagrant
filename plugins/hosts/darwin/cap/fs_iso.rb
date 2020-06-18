require "tempfile"
require 'fileutils'
require 'pathname'
require "vagrant/util/subprocess"
require "vagrant/util/map_command_options"
require "vagrant/util/directory"

module VagrantPlugins
  module HostDarwin
    module Cap
      class FsISO
        @@logger = Log4r::Logger.new("vagrant::host::darwin::fs_iso")

        BUILD_ISO_CMD = "hdiutil".freeze

        # Check that the host has the ability to generate ISOs
        #
        # @param [Vagrant::Environment] env
        # @return [Boolean]
        def self.isofs_available(env)
          !!Vagrant::Util::Which.which(BUILD_ISO_CMD)
        end

        # Generate an ISO file of the given source directory
        #
        # @param [Vagrant::Environment] env
        # @param [String] source_directory Contents of ISO
        # @param [Map] extra arguments to pass to the iso building command
        #              :file_destination (string) location to store ISO
        #              :volume_id (String) to set the volume name 
        # @return [Pathname] ISO location
        # @note If file_destination exists, source_directory will be checked
        #       for recent modifications and a new ISO will be generated if requried.
        def self.create_iso(env, source_directory, **extra_opts)
          file_destination = extra_opts[:file_destination]
          source_directory = Pathname.new(source_directory)
          if file_destination.nil?
            @@logger.info("No file destination specified, creating temp location")
            tmpfile = Tempfile.new(["vagrant", ".iso"])
            file_destination = Pathname.new(tmpfile.path)
            tmpfile.delete
          else
            file_destination = Pathname.new(file_destination.to_s)
            # If the file destination path is a folder, target the output to a randomly named
            # file in that dir
            if file_destination.extname != ".iso"
              file_destination = file_destination.join("#{SecureRandom.hex(3)}_vagrant.iso")
            end
          end
          # Ensure destination directory is available
          FileUtils.mkdir_p(File.dirname(file_destination.to_s))

          # If the destrination does not exist or there have been changes in the source directory since the last build, then build
          if !file_destination.exist? || Vagrant::Util::Directory.directory_changed?(source_directory, file_destination.mtime)
            @@logger.info("Building ISO from source #{source_directory}")
            iso_command = [BUILD_ISO_CMD, "makehybrid"]
            iso_command << "-hfs"
            iso_command << "-iso"
            iso_command << "-joliet"
            iso_command << "-ov"
            iso_command.concat(["-default-volume-name", extra_opts[:volume_id]]) if extra_opts[:volume_id]
            iso_command << "-o"
            iso_command << file_destination.to_s
            iso_command << source_directory.to_s
            result = Vagrant::Util::Subprocess.execute(*iso_command)
            
            if result.exit_code != 0
              raise Vagrant::Errors::ISOBuildFailed, cmd: iso_command.join(" "), stdout: result.stdout, stderr: result.stderr
            end
          end

          @@logger.info("ISO available at #{file_destination}")
          file_destination
        end
      end
    end
  end
end
