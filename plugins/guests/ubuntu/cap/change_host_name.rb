module VagrantPlugins
  module GuestUbuntu
    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          comm = machine.communicate

          if !comm.test("hostname -f | grep -w '#{name}'")
            basename = name.split(".", 2)[0]
            comm.sudo <<-EOH.gsub(/^ {14}/, '')
              set -e

              # Set the hostname
              echo '#{name}' > /etc/hostname
              hostname -F /etc/hostname

              if command -v hostnamectl; then
                hostnamectl set-hostname '#{name}'
              fi

              # Remove comments and blank lines from /etc/hosts
              sed -i'' -e 's/#.*$//' -e '/^$/d' /etc/hosts

              # Prepend ourselves to /etc/hosts
              grep -w '#{name}' /etc/hosts || {
                sed -i'' '1i 127.0.0.1\\t#{name}\\t#{basename}' /etc/hosts
              }

              # Update mailname
              echo '#{name}' > /etc/mailname

              # Restart networking and force new DHCP
              if [ test -f /etc/init.d/hostname ]; then
                /etc/init.d/hostname start || true
              fi

              if [ test -f /etc/init.d/hostname.sh ]; then
                /etc/init.d/hostname.sh start || true
              fi

              if [ test -f /etc/init.d/networking ]; then
                /etc/init.d/networking force-reload
              fi

              if [ test -f /etc/init.d/network-manager ]; then
                /etc/init.d/network-manager force-reload
              fi
            EOH
          end
        end
      end
    end
  end
end
