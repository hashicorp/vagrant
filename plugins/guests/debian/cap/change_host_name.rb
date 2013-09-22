module VagrantPlugins
  module GuestDebian
    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          machine.communicate.tap do |comm|

            # Get the current hostname
            # if existing fqdn setup improperly, this returns just hostname
            old = ''
            comm.sudo "hostname -f" do |type, data|
             if type == :stdout
               old = data.chomp
             end
            end

            # this works even if they're not both fqdn
            if old.split('.')[0] != name.split('.')[0]

              comm.sudo("sed -i 's/.*$/#{name.split('.')[0]}/' /etc/hostname")

              # hosts should resemble:
              # 127.0.1.1   host.fqdn.com host
              # First to set fqdn
              comm.sudo("sed -i 's@#{old}@#{name}@' /etc/hosts")
              # Second to set hostname
              comm.sudo("sed -i 's@#{old.split('.')[0]}@#{name.split('.')[0]}@' /etc/hosts")

              comm.sudo("hostname -F /etc/hostname")
              comm.sudo("hostname --fqdn > /etc/mailname")
              comm.sudo("ifdown -a; ifup -a; ifup eth0")
            end
          end
        end
      end
    end
  end
end
