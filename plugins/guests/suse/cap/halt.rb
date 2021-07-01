module VagrantPlugins
  module GuestSUSE
    module Cap
      class Halt
        def self.halt(machine)
          begin
            machine.communicate.sudo("/usr/bin/systemctl poweroff &")
          rescue IOError, Vagrant::Errors::SSHDisconnected
            # Do nothing, because it probably means the machine shut down
            # and SSH connection was lost.
          end
        end
      end
    end
  end
end
