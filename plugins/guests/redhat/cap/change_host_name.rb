module VagrantPlugins
  module GuestRedHat
    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          machine.communicate.tap do |comm|
            # Only do this if the hostname is not already set
            if !comm.test("sudo hostname -f | grep --line-regexp '#{name}'")
              short_name = name.split('.')[0]
              comm.sudo("sed -i 's/\\(HOSTNAME=\\).*/\\1#{name}/' /etc/sysconfig/network")
              comm.sudo("hostname #{short_name}")
              comm.sudo("sed -i 's@^\\(127[.]0[.]0[.]1[[:space:]]\\+\\)@\\1#{name} #{short_name} @' /etc/hosts")
              comm.sudo("sed -i 's/\\(DHCP_HOSTNAME=\\).*/\\1\"#{short_name}\"/' /etc/sysconfig/network-scripts/ifcfg-*")
              comm.sudo("service network restart")
            end
          end
        end
      end
    end
  end
end
