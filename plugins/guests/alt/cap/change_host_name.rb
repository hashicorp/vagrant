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

              # Update sysconfig
              sed -i 's/\\(HOSTNAME=\\).*/\\1#{name}/' /etc/sysconfig/network

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

              # Restart network
              service network restart
            EOH
          end
        end
      end
    end
  end
end
