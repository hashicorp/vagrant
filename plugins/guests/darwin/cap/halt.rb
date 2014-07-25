module VagrantPlugins
  module GuestDarwin
    module Cap
      class Halt
        def self.halt(machine)
          machine.communicate.sudo('shutdown -h now')
        rescue IOError
        end
      end
    end
  end
end
