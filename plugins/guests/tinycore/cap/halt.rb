module VagrantPlugins
  module GuestTinyCore
    module Cap
      class Halt
        def self.halt(machine)
          machine.communicate.sudo('poweroff')
        rescue Net::SSH::Disconnect, IOError
        end
      end
    end
  end
end
