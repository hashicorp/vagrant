require 'vagrant/util/guest_inspection'

module VagrantPlugins
  module GuestLinux
    module Cap
      class Halt
        extend Vagrant::Util::GuestInspection::Linux

        def self.halt(machine)
          begin
            if systemd?(machine.communicate)
              machine.communicate.sudo("systemctl poweroff")
            else
              machine.communicate.sudo("shutdown -h now")
            end
          rescue IOError, Vagrant::Errors::SSHDisconnected
            # Do nothing, because it probably means the machine shut down
            # and SSH connection was lost.
          end
        end
      end
    end
  end
end
