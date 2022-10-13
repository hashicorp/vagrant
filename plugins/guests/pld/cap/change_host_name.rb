require_relative '../../linux/cap/change_host_name'

module VagrantPlugins
  module GuestPld
    module Cap
      class ChangeHostName
        extend VagrantPlugins::GuestLinux::Cap::ChangeHostName

        def self.change_name_command(name)
          return <<-EOH.gsub(/^ {14}/, "")
          hostname '#{name}'
          sed -i 's/\\(HOSTNAME=\\).*/\\1#{name}/' /etc/sysconfig/network

          sed -i 's/\\(DHCP_HOSTNAME=\\).*/\\1\"#{name}\"/' /etc/sysconfig/interfaces/ifcfg-*

          # Restart networking
          service network restart
          EOH
        end
      end
    end
  end
end
