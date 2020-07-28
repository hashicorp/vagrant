require "tempfile"
require "fileutils"
require "pathname"
require "vagrant/util/directory"
require "vagrant/util/subprocess"

module Vagrant
  module Util
    module Caps
      module BuildISO

        # Builds an iso given a compatible iso_command
        #
        # @param [List<String>] command to build iso
        # @param [Pathname] input directory for iso build
        # @param [Pathname] output file for iso build
        def build_iso(iso_command, source_directory, file_destination)
          FileUtils.mkdir_p(file_destination.dirname)
          if !file_destination.exist? || Vagrant::Util::Directory.directory_changed?(source_directory, file_destination.mtime)
            result = Vagrant::Util::Subprocess.execute(*iso_command)
            if result.exit_code != 0
              raise Vagrant::Errors::ISOBuildFailed, cmd: iso_command.join(" "), stdout: result.stdout, stderr: result.stderr
            end
          end
        end

        protected

        def ensure_output_iso(file_destination)
          if file_destination.nil?
            tmpfile = Tempfile.new(["vagrant", ".iso"])
            file_destination = Pathname.new(tmpfile.path)
            tmpfile.close
            tmpfile.unlink
          else
            file_destination = Pathname.new(file_destination.to_s)
            # If the file destination path is a folder, target the output to a randomly named
            # file in that dir
            if file_destination.extname != ".iso"
              file_destination = file_destination.join("#{SecureRandom.hex(3)}_vagrant.iso")
            end
          end
          file_destination
        end
      end
    end
  end
end
