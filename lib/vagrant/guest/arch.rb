module Vagrant
  module Guest
    class Arch < Linux
      def change_host_name(name)
        vm.ssh.execute do |ssh|
          # Only do this if the hostname is not already set
          if !ssh.test?("sudo hostname | grep '#{name}'")
            ssh.exec!("sudo sed -i 's/\\(HOSTNAME=\\).*/\\1#{name}/' /etc/rc.conf")
            ssh.exec!("sudo hostname #{name}")
            ssh.exec!("sudo sed -i 's@^\\(127[.]0[.]0[.]1[[:space:]]\\+\\)@\\1#{name} @' /etc/hosts")
          end
        end
      end

      def prepare_host_only_network(net_options=nil)
        vm.ssh.execute do |ssh|
          ssh.exec!("sudo sed -e '/^#VAGRANT-BEGIN/,/^#VAGRANT-END/ d' /etc/rc.conf > /tmp/vagrant-network-interfaces")
          ssh.exec!("sudo su -c 'cat /tmp/vagrant-network-interfaces > /etc/rc.conf'")
        end
      end

      def enable_host_only_network(net_options)
        entry = TemplateRenderer.render('network_entry_arch', :net_options => net_options)
        vm.ssh.upload!(StringIO.new(entry), "/tmp/vagrant-network-entry")

        vm.ssh.execute do |ssh|
          ssh.exec!("sudo su -c 'cat /tmp/vagrant-network-entry >> /etc/rc.conf'")
          ssh.exec!("sudo /etc/rc.d/network restart")
          ssh.exec!("sudo su -c 'dhcpcd -k eth0 && dhcpcd eth0 & sleep 3'")
        end
      end
    end
  end
end
