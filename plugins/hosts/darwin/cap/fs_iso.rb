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
        # @param [String, nil] file_destination Location to store ISO
        # @param [Map] extra arguments to pass to the iso building command
        # @return [Pathname] ISO location
        # @note If file_destination exists, source_directory will be checked
        #       for recent modifications and a new ISO will be generated if requried.
        def self.create_iso(env, source_directory, file_destination=nil, extra_opts={})
          file_destination = output_file(file_destination)
          source_directory = Pathname.new(source_directory)

          # If the destrination does not exist or there have been changes in the source directory since the last build, then build
          if !file_destination.exist? || Vagrant::Util::Directory.directory_changed?(source_directory, file_destination.mtime)
            @@logger.info("Building ISO from source #{source_directory}")
            iso_command = [BUILD_ISO_CMD, "makehybrid"]
            iso_command << "-hfs"
            iso_command << "-iso"
            iso_command << "-joliet"
            iso_command.concat(Vagrant::Util::MapCommandOptions.map_to_command_options(extra_opts, cmd_flag="-"))
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

        # Determines a valid file path for an output file
        # and ensures parent directory exists
        #
        # @param [String, nil] (optional) path to output file
        # @return [Pathname] path to output file
        def self.output_file(file_destination=nil)
          if file_destination.nil?
            @@logger.info("No file destination specified, creating temp location")
            tmpfile = Tempfile.new("vagrant-iso")
            file_destination = Pathname.new(tmpfile.path)
            tmpfile.delete
          else
            file_destination = Pathname.new(file_destination.to_s)
            if file_destination.extname != ".iso"
              file_destination = file_destination.join("#{rand(36**6).to_s(36)}_vagrant-iso")
            end
          end
          @@logger.info("Targeting to create ISO at #{file_destination}")
          # Ensure destination directory is available
          FileUtils.mkdir_p(File.dirname(file_destination.to_s))
          file_destination
        end
      end
    end
  end
end
