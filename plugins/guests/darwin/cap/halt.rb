module VagrantPlugins
  module GuestDarwin
    module Cap
      class Halt
        def self.halt(machine)
          begin
            # Darwin does not support the `-p` option like the rest of the
            # BSD-based guests, so it needs its own cap.
            machine.communicate.sudo("/sbin/shutdown -h now")
          rescue IOError, Vagrant::Errors::SSHDisconnected
            # Do nothing because SSH connection closed and it probably
            # means the VM just shut down really fast.
          end
        end
      end
    end
  end
end
