require "tempfile"

module VagrantPlugins
  module HostDarwin
    module Cap
      class FsISO
        @@logger = Log4r::Logger.new("vagrant::host::darwin::fs_iso")

        # Check that the host has the ability to generate ISOs
        #
        # @param [Vagrant::Environment] env
        # @return [Boolean]
        def self.isofs_available(env)
          !!Vagrant::Util::Which.which("hdiutil")
        end

        # Generate an ISO file of the given source directory
        #
        # @param [Vagrant::Environment] env
        # @param [String, Pathname] source_directory Contents of ISO
        # @param [String, Pathname, nil] file_destination Location to store ISO
        # @return [Pathname] ISO location
        # @note If file_destination exists, source_directory will be checked
        #       for recent modifications and a new ISO will be generated if requried.
        def self.create_iso(env, source_directory, file_destination=nil)
          if file_destination.nil?
            tmpfile = Tempfile.new("vagrant-iso")
            file_destination = Pathname.new(tmpfile.path)
            tmpfile.delete
          else
            file_destination = Pathname.new(file_destination.to_s)
          end
          source_directory = Pathname.new(source_directory)
          if iso_update_required?(file_destination, source_directory)
            # Ensure destination directory is available
            FileUtils.mkdir_p(file_destination.to_s)
            result = Vagrant::Util::Subprocess.execute("hdiutil", "makehybrid", "-o",
              file_destination.to_s, "-hfs", "-joliet", "-iso", "-default-volume-name",
              "cidata", source_directory.to_s)
            if result.exit_code != 0
              raise "Failed to create ISO!"
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
            if File.mtime > iso_path.mtime
              return true
            end
          end
          false
        end
      end
    end
  end
end
