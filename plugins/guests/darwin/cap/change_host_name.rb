module VagrantPlugins
  module GuestDarwin
    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          if !machine.communicate.test("hostname -f | grep '^#{name}$' || hostname -s | grep '^#{name}$'")
            machine.communicate.sudo("scutil --set ComputerName #{name}")
            machine.communicate.sudo("scutil --set HostName #{name}")
            # LocalHostName shouldn't contain dots.
            # It is used by Bonjour and visible through file sharing services.
            machine.communicate.sudo("scutil --set LocalHostName #{name.gsub(/\.+/, '')}")
            machine.communicate.sudo("hostname #{name}")
          end
        end
      end
    end
  end
end
