module VagrantPlugins
  module GuestPld
    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          comm = machine.communicate

          if !comm.test("hostname -f | grep '^#{name}$'", sudo: false)
            basename = name.split(".", 2)[0]
            comm.sudo <<-EOH.gsub(/^ {14}/, '')
              hostname '#{name}'
              sed -i 's/\\(HOSTNAME=\\).*/\\1#{name}/' /etc/sysconfig/network

              sed -i 's/\\(DHCP_HOSTNAME=\\).*/\\1\"#{name}\"/' /etc/sysconfig/interfaces/ifcfg-*

              # Prepend ourselves to /etc/hosts
              grep -w '#{name}' /etc/hosts || {
                sed -i'' '1i 127.0.0.1\\t#{name}\\t#{basename}' /etc/hosts
              }

              # Restart networking
              service network restart
            EOH
          end
        end
      end
    end
  end
end
