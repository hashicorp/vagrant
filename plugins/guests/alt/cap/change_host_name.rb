require 'vagrant/util/guest_hosts'

module VagrantPlugins
  module GuestALT
    module Cap
      class ChangeHostName
        extend Vagrant::Util::GuestHosts::Linux

        def self.change_host_name(machine, name)
          comm = machine.communicate

          network_with_hostname = machine.config.vm.networks.map {|_, c| c if c[:hostname] }.compact[0]
          if network_with_hostname
            replace_host(comm, name, network_with_hostname[:ip])
          else
            add_hostname_to_loopback_interface(comm, name)
          end

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
