module VagrantPlugins
  module GuestNetBSD
    module Cap
      class Halt
        def self.halt(machine)
          machine.communicate.sudo('/sbin/shutdown -p -h now')
        rescue IOError
        end
      end
    end
  end
end
