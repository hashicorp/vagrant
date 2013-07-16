module VagrantPlugins
  module GuestDebian
    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          machine.communicate.tap do |comm|
            if !comm.test("hostname --fqdn | grep '^#{name}$' || hostname --short | grep '^#{name}$'")
              comm.sudo("sed -r -i 's/^(127[.]0[.]1[.]1[[:space:]]+).*$/\\1#{name} #{name.split('.')[0]}/' /etc/hosts")
              comm.sudo("sed -i 's/.*$/#{name.split('.')[0]}/' /etc/hostname")
              comm.sudo("hostname -F /etc/hostname")
              comm.sudo("hostname --fqdn > /etc/mailname")
              comm.sudo("ifdown -a; ifup -a")
            end
          end
        end
      end
    end
  end
end
