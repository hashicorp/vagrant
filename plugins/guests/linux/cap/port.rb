module VagrantPlugins
  module GuestLinux
    module Cap
      class Port
        def self.port_open_check(machine, port)
          machine.communicate.test("nc -z -w2 127.0.0.1 #{port}")
        end
      end
    end
  end
end
