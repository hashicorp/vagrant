module VagrantPlugins
  module GuestDebian
    module Cap
      class ChangeHostName
        # For more information, please see:
        #
        #   https://wiki.debian.org/HowTo/ChangeHostname
        #
        def self.change_host_name(machine, name)
          comm = machine.communicate

          if !comm.test("hostname -f | grep '^#{name}$'", sudo: false)
            basename = name.split(".", 2)[0]
            comm.sudo <<-EOH.gsub(/^ {14}/, '')
              # Set the hostname
              echo '#{basename}' > /etc/hostname
              hostname -F /etc/hostname

              # Remove comments and blank lines from /etc/hosts
              sed -i'' -e 's/#.*$//' -e '/^$/d' /etc/hosts

              # Prepend ourselves to /etc/hosts
              grep -w '#{name}' /etc/hosts || {
                sed -i'' '1i 127.0.0.1\\t#{name}\\t#{basename}' /etc/hosts
              }

              # Update mailname
              echo '#{name}' > /etc/mailname

              # Restart networking and force new DHCP
              if [ test -f /etc/init.d/hostname.sh ]; then
                invoke-rc.d hostname.sh start
              fi

              if [ test -f /etc/init.d/networking ]; then
                invoke-rc.d networking force-reload
              fi

              if [ test -f /etc/init.d/network-manager ]; then
                invoke-rc.d network-manager force-reload
              fi
            EOH
          end
        end
      end
    end
  end
end
