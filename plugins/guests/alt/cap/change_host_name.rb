require_relative '../../linux/cap/change_host_name'

module VagrantPlugins
  module GuestALT
    module Cap
      class ChangeHostName
        extend VagrantPlugins::GuestLinux::Cap::ChangeHostName
        
        def self.change_name_command(name)
          basename = name.split(".", 2)[0]
          return <<-EOH.gsub(/^ {14}/, '')
          # Save current hostname saved in /etc/hosts
          CURRENT_HOSTNAME_FULL="$(hostname -f)"
          CURRENT_HOSTNAME_SHORT="$(hostname -s)"

          # Set the hostname - use hostnamectl if available
          if command -v hostnamectl; then
            hostnamectl set-hostname --static '#{name}'
            hostnamectl set-hostname --transient '#{name}'
          else
            hostname '#{name}'
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
