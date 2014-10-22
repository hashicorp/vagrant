module VagrantPlugins
  module FileDeploy
    class Push < Vagrant.plugin("2", :push)
      def push
        @machine.communicate.tap do |comm|
          destination = expand_guest_path(config.destination)

          # Make sure the remote path exists
          command = "mkdir -p %s" % File.dirname(destination)
          comm.execute(command)

          # Now push the deploy...
          # ???
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
