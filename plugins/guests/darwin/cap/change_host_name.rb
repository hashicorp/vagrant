module VagrantPlugins
  module GuestDarwin
    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          if !machine.communicate.test("hostname -f | grep '^#{name}$' || hostname -s | grep '^#{name}$'")
            machine.communicate.sudo("scutil --set HostName #{name}")
            machine.communicate.sudo("hostname #{name}")
          end
        end
      end
    end
  end
end
