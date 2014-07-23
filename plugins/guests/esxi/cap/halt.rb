module VagrantPlugins
  module GuestEsxi
    module Cap
      class Halt
        def self.halt(machine)
          machine.communicate.execute('/bin/halt -d 0')
        rescue IOError
        end
      end
    end
  end
end
