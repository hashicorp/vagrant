module VagrantPlugins
  module GuestOpenBSD
    module Cap
      class Halt
        def self.halt(machine)
          machine.communicate.sudo('shutdown -p -h now')
        rescue IOError
        end
      end
    end
  end
end
