module VagrantPlugins
  module GuestSuse
    module Cap
      class Halt
        def self.halt(machine)
          machine.communicate.sudo('/sbin/shutdown -h now')
        rescue IOError
        end
      end
    end
  end
end
