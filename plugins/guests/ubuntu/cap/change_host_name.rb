module VagrantPlugins
  module GuestUbuntu
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
              # 127.0.0.1   localhost host.fqdn.com host
              # 127.0.1.1   host.fqdn.com host
              comm.sudo("sed -ri 's@^(([0-9]{1,3}\.){3}[0-9]{1,3})\\s+(localhost)\\b.*$@\\1\\t#{name} #{name.split('.')[0]} \\3@g' /etc/hosts")
              comm.sudo("sed -ri 's@^(([0-9]{1,3}\.){3}[0-9]{1,3})\\s+(precise64)\\b.*$@\\1\\t#{name} #{name.split('.')[0]}@g' /etc/hosts")

              if comm.test("[ `lsb_release -c -s` = hardy ]")
                # hostname.sh returns 1, so I grep for the right name in /etc/hostname just to have a 0 exitcode
                comm.sudo("/etc/init.d/hostname.sh start; grep '#{name}' /etc/hostname")
              else
                comm.sudo("service hostname start")
              end
              comm.sudo("hostname --fqdn > /etc/mailname")
              comm.sudo("ifdown -a; ifup -a; ifup -a --allow=hotplug")
            end
          end
        end
      end
    end
  end
end
