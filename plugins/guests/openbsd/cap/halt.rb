module VagrantPlugins
  module GuestOpenBSD
    module Cap
      class Halt
        def self.halt(machine)
          begin
            # Versions of OpenBSD prior to 5.7 require the -h option to be
            # provided with the -p option. Later options allow the -h to
            # be optional.
            machine.communicate.sudo("/sbin/shutdown -p -h now", shell: "sh")
          rescue IOError, Vagrant::Errors::SSHDisconnected
            # Do nothing, because it probably means the machine shut down
            # and SSH connection was lost.
          end
        end
      end
    end
  end
end
