module VagrantPlugins
  module GuestRedHat
    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          comm = machine.communicate

          if !comm.test("hostname -f | grep '^#{name}$'", sudo: false)
            basename = name.split('.', 2)[0]
            comm.sudo <<-EOH.gsub(/^ {14}/, '')
              # Update sysconfig
              sed -i 's/\\(HOSTNAME=\\).*/\\1#{name}/' /etc/sysconfig/network

              # Update DNS
              sed -i 's/\\(DHCP_HOSTNAME=\\).*/\\1\"#{basename}\"/' /etc/sysconfig/network-scripts/ifcfg-*

              # Set the hostname - use hostnamectl if available
              echo '#{name}' > /etc/hostname
              if command -v hostnamectl; then
                hostnamectl set-hostname --static '#{name}'
                hostnamectl set-hostname --transient '#{name}'
              else
                hostname -F /etc/hostname
              fi

              # Remove comments and blank lines from /etc/hosts
              sed -i'' -e 's/#.*$//' -e '/^$/d' /etc/hosts

              # Prepend ourselves to /etc/hosts
              grep -w '#{name}' /etc/hosts || {
                sed -i'' '1i 127.0.0.1\\t#{name}\\t#{basename}' /etc/hosts
              }

              # Restart network (through NetworkManager if running)
              if service NetworkManager status 2>&1 | grep -q running; then
                service NetworkManager restart
              else
                service network restart
              fi
            EOH
          end
        end
      end
    end
  end
end
