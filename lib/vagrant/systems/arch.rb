module Vagrant
  module Systems
    class Arch < Linux
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
