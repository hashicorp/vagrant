module VagrantPlugins
  module FileUpload
    class Provisioner < Vagrant.plugin("2", :provisioner)
      def provision
        @machine.communicate.tap do |comm|
          destination = expand_guest_path(config.destination)

          # Make sure the remote path exists
          command = "mkdir -p %s" % File.dirname(destination)
          comm.execute(command)

          # now upload the file
          comm.upload(File.expand_path(config.source), destination)
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
