module VagrantPlugins
  module GuestEsxi
    module Cap
      class Halt
        def self.halt(machine)
          begin
            machine.communicate.execute("/bin/halt -d 0")
          rescue IOError, Vagrant::Errors::SSHDisconnected
            # Ignore, this probably means connection closed because it
            # shut down.
          end
        end
      end
    end
  end
end
