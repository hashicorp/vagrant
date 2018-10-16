module VagrantPlugins
  module GuestDebian
    module Cap
      class ChangeHostName

        extend Vagrant::Util::GuestInspection::Linux

        def self.change_host_name(machine, name)
          comm = machine.communicate

          if !comm.test("hostname -f | grep '^#{name}$'", sudo: false)
            basename = name.split(".", 2)[0]
            comm.sudo <<-EOH.gsub(/^ {14}/, '')
              # Set the hostname
              echo '#{basename}' > /etc/hostname

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

            EOH

            if hostnamectl?(comm)
              comm.sudo("hostnamectl set-hostname '#{basename}'")
            else
              comm.sudo <<-EOH.gsub(/^ {14}/, '')
              hostname -F /etc/hostname
              # Restart hostname services
              if test -f /etc/init.d/hostname; then
                /etc/init.d/hostname start || true
              fi

              if test -f /etc/init.d/hostname.sh; then
                /etc/init.d/hostname.sh start || true
              fi
              EOH
            end

            restart_command = "/etc/init.d/networking restart"

            if systemd?(comm)
              if systemd_networkd?(comm)
                restart_command = "systemctl restart systemd-networkd.service"
              elsif systemd_controlled?(comm, "NetworkManager.service")
                restart_command = "systemctl restart NetworkManager.service"
              end
            end
            comm.sudo(restart_command)
          end
        end
      end
    end
  end
end
