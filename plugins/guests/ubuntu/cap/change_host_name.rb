module VagrantPlugins
  module GuestUbuntu
    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          machine.communicate.tap do |comm|
            if !comm.test("sudo hostname | grep '^#{name}$'")
              comm.sudo("sed -i 's/.*$/#{name}/' /etc/hostname")
              comm.sudo("sed -i 's@^\\(127[.]0[.]1[.]1[[:space:]]\\+\\)@\\1#{name} #{name.split('.')[0]} @' /etc/hosts")
              if comm.test("[ `lsb_release -c -s` = hardy ]")
                # hostname.sh returns 1, so I grep for the right name in /etc/hostname just to have a 0 exitcode
                comm.sudo("/etc/init.d/hostname.sh start; grep '#{name}' /etc/hostname")
              else
                comm.sudo("service hostname start")
              end
              comm.sudo("hostname --fqdn > /etc/mailname")
              comm.sudo("ifdown -a; ifup -a")
            end
          end
        end
      end
    end
  end
end
