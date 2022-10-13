require "pathname"
require "vagrant/util/caps"

module VagrantPlugins
  module HostDarwin
    module Cap
      class FsISO
        extend Vagrant::Util::Caps::BuildISO
        
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
        def self.create_iso(env, source_directory, extra_opts={})
          source_directory = Pathname.new(source_directory)
          file_destination = self.ensure_output_iso(extra_opts[:file_destination])

          iso_command = [BUILD_ISO_CMD, "makehybrid", "-hfs", "-iso", "-joliet", "-ov"]
          iso_command.concat(["-default-volume-name", extra_opts[:volume_id]]) if extra_opts[:volume_id]
          iso_command << "-o"
          iso_command << file_destination.to_s
          iso_command << source_directory.to_s
          self.build_iso(iso_command, source_directory, file_destination)

          @@logger.info("ISO available at #{file_destination}")
          file_destination
        end
      end
    end
  end
end
