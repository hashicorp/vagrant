require 'vagrant/util/guest_hosts'

module VagrantPlugins
  module GuestRedHat
    module Cap
      class ChangeHostName

        extend Vagrant::Util::GuestInspection::Linux
        extend Vagrant::Util::GuestHosts::Linux

        def self.change_host_name(machine, name)
          comm = machine.communicate

          if !comm.test("hostname -f | grep '^#{name}$'", sudo: false)
            basename = name.split('.', 2)[0]
            comm.sudo <<-EOH.gsub(/^ {14}/, '')
              # Update sysconfig
              sed -i 's/\\(HOSTNAME=\\).*/\\1#{name}/' /etc/sysconfig/network
              # Update DNS
              sed -i 's/\\(DHCP_HOSTNAME=\\).*/\\1\"#{basename}\"/' /etc/sysconfig/network-scripts/ifcfg-*
            EOH

            if hostnamectl?(comm)
              comm.sudo("hostnamectl set-hostname --static '#{name}' ; " \
                "hostnamectl set-hostname --transient '#{name}'")
            else
              comm.sudo("hostname -F /etc/hostname")
            end

            restart_command = "service network restart"

            if systemd?(comm)
              if systemd_networkd?(comm)
                restart_command = "systemctl restart systemd-networkd.service"
              elsif systemd_controlled?(comm, "NetworkManager.service")
                restart_command = "systemctl restart NetworkManager.service"
              end
            end
            comm.sudo(restart_command)
          end
          
          network_with_hostname = machine.config.vm.networks.map {|_, c| c if c[:hostname] }.compact[0]
          if network_with_hostname
            replace_host(comm, name, network_with_hostname[:ip])
          else
            add_hostname_to_loopback_interface(comm, name)
          end
        end
      end
    end
  end
end
