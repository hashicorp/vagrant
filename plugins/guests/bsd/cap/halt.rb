module VagrantPlugins
  module GuestBSD
    module Cap
      class Halt
        def self.halt(machine)
          begin
            machine.communicate.sudo("/sbin/shutdown -p -h now", shell: "sh")
          rescue IOError
            # Do nothing, because it probably means the machine shut down
            # and SSH connection was lost.
          end
        end
      end
    end
  end
end
