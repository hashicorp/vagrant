require "tempfile"
require 'fileutils'
require 'pathname'
require "vagrant/util/subprocess"
require "vagrant/util/directory"
require "vagrant/util/caps"

module VagrantPlugins
  module HostLinux
    module Cap
      class FsISO
        extend Vagrant::Util::Caps::BuildISO

        @@logger = Log4r::Logger.new("vagrant::host::linux::fs_iso")

        BUILD_ISO_CMD = "mkisofs".freeze

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
          source_directory = Pathname.new(source_directory)
          file_destination = self.ensure_file_destination(extra_opts[:file_destination])

          # If the destrination does not exist or there have been changes in the source directory since the last build, then build
          if !file_destination.exist? || Vagrant::Util::Directory.directory_changed?(source_directory, file_destination.mtime)
            @@logger.info("Building ISO from source #{source_directory}")
            iso_command = [BUILD_ISO_CMD]
            iso_command << "-joliet"
            iso_command.concat(["-volid", extra_opts[:volume_id]]) if extra_opts[:volume_id]
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
