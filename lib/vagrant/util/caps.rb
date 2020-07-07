require "vagrant/util/directory"
require "vagrant/util/subprocess"

module Vagrant
  module Util
    module Caps
      module BuildISO

        BUILD_ISO_CMD = "".freeze

        # Check that the host has the ability to generate ISOs
        #
        # @param [Vagrant::Environment] env
        # @return [Boolean]
        def isofs_available(env)
          !!Vagrant::Util::Which.which(self::BUILD_ISO_CMD)
        end

        def ensure_file_destination(file_destination)
          if file_destination.nil?
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
          FileUtils.mkdir_p(file_destination.dirname)
          file_destination
        end

      end
    end
  end
end
