module VagrantPlugins
  module GuestOpenBSD
    module Cap
      class Halt
        def self.halt(machine)
          begin
            machine.communicate.sudo("shutdown -p -h now")
          rescue IOError
            # Do nothing, because it probably means the machine shut down
            # and SSH connection was lost.
          end
        end
      end
    end
  end
end
