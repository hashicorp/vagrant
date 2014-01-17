module VagrantPlugins
  module GuestTinyCore
    module Cap
      class Halt
        def self.halt(machine)
          begin
            machine.communicate.sudo("poweroff")
          rescue Net::SSH::Disconnect, IOError
            # Do nothing, because it probably means the machine shut down
            # and SSH connection was lost.
          end
        end
      end
    end
  end
end
