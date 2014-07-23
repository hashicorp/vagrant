module VagrantPlugins
  module GuestFreeBSD
    module Cap
      class Halt
        def self.halt(machine)
          machine.communicate.sudo('shutdown -p now', shell: 'sh')
        rescue IOError
        end
      end
    end
  end
end
