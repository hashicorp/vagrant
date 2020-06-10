require "tempfile"
require 'fileutils'
require 'pathname'
require "vagrant/util/subprocess"
require "vagrant/util/map_command_options"

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
        # @param [String, Pathname] source_directory Contents of ISO
        # @param [String, Pathname, nil] file_destination Location to store ISO
        # @param [Map] extra arguments to pass to the iso building command
        # @return [Pathname] ISO location
        # @note If file_destination exists, source_directory will be checked
        #       for recent modifications and a new ISO will be generated if requried.
        def self.create_iso(env, source_directory, file_destination=nil, extra_opts={})
          if file_destination.nil?
            tmpfile = Tempfile.new("vagrant-iso")
            file_destination = Pathname.new(tmpfile.path)
            tmpfile.delete
          else
            file_destination = Pathname.new(file_destination.to_s)
            # Ensure destination directory is available
            FileUtils.mkdir_p(file_destination.to_s)
          end
          source_directory = Pathname.new(source_directory)
          if iso_update_required?(file_destination, source_directory)            
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
          file_destination
        end

        # Check if source directory has any new updates
        #
        # @param [Pathname] iso_path Path to ISO file
        # @param [Pathname] dir_path Path to source directory
        # @return [Boolean]
        def self.iso_update_required?(iso_path, dir_path)
          Dir.glob(dir_path.join("**/**/*")).each do |path|
            if Pathname.new(path).mtime > iso_path.mtime
              return true
            end
          end
          @@logger.info("ISO update not required! No changes found in source path #{dir_path}")
          false
        end
      end
    end
  end
end
