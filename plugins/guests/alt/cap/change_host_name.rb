module VagrantPlugins
  module GuestALT
    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          comm = machine.communicate

          if !comm.test("hostname -f | grep '^#{name}$'", sudo: false)
            basename = name.split('.', 2)[0]
            comm.sudo <<-EOH.gsub(/^ {14}/, '')
              # Save current hostname saved in /etc/hosts
              CURRENT_HOSTNAME_FULL="$(hostname -f)"
              CURRENT_HOSTNAME_SHORT="$(hostname -s)"

              # New hostname to be saved in /etc/hosts
              NEW_HOSTNAME_FULL='#{name}'
              NEW_HOSTNAME_SHORT="${NEW_HOSTNAME_FULL%%.*}"

              # Set the hostname - use hostnamectl if available
              if command -v hostnamectl; then
                hostnamectl set-hostname --static '#{name}'
                hostnamectl set-hostname --transient '#{name}'
              else
                hostname '#{name}'
              fi

              # Update ourselves in /etc/hosts
              if grep -w "$CURRENT_HOSTNAME_FULL" /etc/hosts; then
                sed -i -e "s/\(\s\)$CURRENT_HOSTNAME_FULL\(\s\)/\1$NEW_HOSTNAME_FULL\2/g" -e "s/\(\s\)$CURRENT_HOSTNAME_FULL$/\1$NEW_HOSTNAME_FULL/g" /etc/hosts
              fi
              if grep -w "$CURRENT_HOSTNAME_SHORT" /etc/hosts; then
                sed -i -e "s/\(\s\)$CURRENT_HOSTNAME_SHORT\(\s\)/\1$NEW_HOSTNAME_SHORT\2/g" -e "s/\(\s\)$CURRENT_HOSTNAME_SHORT$/\1$NEW_HOSTNAME_SHORT/g" /etc/hosts
              fi

              # Persist hostname change across reboots
              if [ -f /etc/sysconfig/network ]; then
                sed -i 's/\\(HOSTNAME=\\).*/\\1#{name}/' /etc/sysconfig/network
              elif [ -f /etc/hostname ]; then
                sed -i 's/.*/#{name}/' /etc/hostname
              else
                echo 'Unrecognized system. Hostname change may not persist across reboots.'
                exit 0
              fi

              # Restart the network if we find a recognized SYS V init script
              if command -v service; then
                if [ -f /etc/init.d/network ]; then
                  service network restart
                elif [ -f /etc/init.d/networking ]; then
                  service networking restart
                elif [ -f /etc/init.d/NetworkManager ]; then
                  service NetworkManager restart
                else
                  echo 'Unrecognized system. Networking was not restarted following hostname change.'
                  exit 0
                fi
              fi

            EOH
          end
        end
      end
    end
  end
end
