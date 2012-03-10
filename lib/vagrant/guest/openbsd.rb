module Vagrant
  module Guest
    class OpenBSD < Base
      def halt
        vm.channel.sudo("shutdown -p -h now")

        # Wait until the VM's state is actually powered off. If this doesn't
        # occur within a reasonable amount of time then simply return which
        # will cause Vagrant to force kill the machine.
        count = 0
        while vm.state != :poweroff
          count += 1

          return if count >= 30
          sleep 1
        end
      end
    end
  end
end
