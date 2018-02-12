module VagrantPlugins
  module GuestDebian
    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          comm = machine.communicate

          if !comm.test("hostname -f | grep '^#{name}$'", sudo: false)
            basename = name.split(".", 2)[0]
            comm.sudo <<-EOH.gsub(/^ {14}/, '')
              # Set the hostname
              echo '#{basename}' > /etc/hostname
              hostname -F /etc/hostname

              if command -v hostnamectl; then
                hostnamectl set-hostname '#{basename}'
              fi

              # Prepend ourselves to /etc/hosts
              grep -w '#{name}' /etc/hosts || {
                if grep -w '^127\\.0\\.1\\.1' /etc/hosts ; then
                  sed -i'' 's/^127\\.0\\.1\\.1\\s.*$/127.0.1.1\\t#{name}\\t#{basename}/' /etc/hosts
                else
                  sed -i'' '1i 127.0.1.1\\t#{name}\\t#{basename}' /etc/hosts
                fi
              }

              # Update mailname
              echo '#{name}' > /etc/mailname

              # Restart hostname services
              if test -f /etc/init.d/hostname; then
                /etc/init.d/hostname start || true
              fi

              if test -f /etc/init.d/hostname.sh; then
                /etc/init.d/hostname.sh start || true
              fi
              if test -x /sbin/dhclient ; then
                /sbin/dhclient -r
                /sbin/dhclient -nw
              fi
            EOH
          end
        end
      end
    end
  end
end
