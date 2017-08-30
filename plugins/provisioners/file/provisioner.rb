module VagrantPlugins
  module FileUpload
    class Provisioner < Vagrant.plugin("2", :provisioner)
      def provision
        @machine.communicate.tap do |comm|
          source = File.expand_path(config.source)
          destination = expand_guest_path(config.destination)

          # if source is a directory, make it then trim destination with dirname
          # Make sure the remote path exists
          if File.directory?(source)
            # We need to make sure the actual destination folder
            # also exists before uploading, otherwise
            # you will get nested folders
            #
            # https://serverfault.com/questions/538368/make-scp-always-overwrite-or-create-directory
            # https://unix.stackexchange.com/questions/292641/get-scp-path-behave-like-rsync-path/292732
            command = "mkdir -p \"%s\"" % destination
            if !destination.end_with?(File::SEPARATOR) &&
                !source.end_with?("#{File::SEPARATOR}.")
              # We also need to append a '/.' to the source folder so we copy
              # the contents rather than the folder itself, in case a users
              # destination folder differs from its source
              #
              # If source is set as `source/` it will lose the trailing
              # slash due to how `File.expand_path` works, so we don't need
              # a conditional for that case.
              if @machine.config.vm.communicator == :winrm
                # windows needs an array of paths because of the
                # winrm-fs function Vagrant is using to upload file/folder.
                source = Dir["#{source}#{File::SEPARATOR}*"]
              else
                source << "#{File::SEPARATOR}."
              end
            end
          else
            command = "mkdir -p \"%s\"" % File.dirname(destination)
          end
          comm.execute(command)

          # now upload the file
          comm.upload(source, destination)
        end
      end

      private

      # Expand the guest path if the guest has the capability
      def expand_guest_path(destination)
        if machine.guest.capability?(:shell_expand_guest_path)
          machine.guest.capability(:shell_expand_guest_path, destination)
        else
          destination
        end
      end
    end
  end
end
