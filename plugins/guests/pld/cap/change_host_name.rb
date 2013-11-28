module VagrantPlugins
  module GuestPld
    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          machine.communicate.tap do |comm|
            # Only do this if the hostname is not already set
            if !comm.test("sudo hostname | grep --line-regexp '#{name}'")
              comm.sudo("sed -i 's/\\(HOSTNAME=\\).*/\\1#{name}/' /etc/sysconfig/network")
              comm.sudo("hostname #{name}")
              comm.sudo("sed -i 's@^\\(127[.]0[.]0[.]1[[:space:]]\\+\\)@\\1#{name} #{name.split('.')[0]} @' /etc/hosts")
              comm.sudo("sed -i 's/\\(DHCP_HOSTNAME=\\).*/\\1\"#{name}\"/' /etc/sysconfig/interfaces/ifcfg-*")
              comm.sudo("service network restart")
            end
          end
        end
      end
    end
  end
end
