module VagrantPlugins
  module GuestSmartos
    module Cap
      class Halt
        def self.halt(machine)
          # There should be an exception raised if the line
          #
          #     vagrant::::profiles=Primary Administrator
          #
          # does not exist in /etc/user_attr. TODO
          begin
            machine.communicate.execute(
              "#{machine.config.smartos.suexec_cmd} /usr/sbin/poweroff")
          rescue IOError, Vagrant::Errors::SSHDisconnected
            # Ignore, this probably means connection closed because it
            # shut down.
          end
        end
      end
    end
  end
end
