module Vagrant
  module Systems
    class Debian < Linux
      def prepare_host_only_network(net_options=nil)
        # Remove any previous host only network additions to the
        # interface file.
        vm.ssh.execute do |ssh|
          # Clear out any previous entries
          ssh.exec!("sudo sed -e '/^#VAGRANT-BEGIN/,/^#VAGRANT-END/ d' /etc/network/interfaces > /tmp/vagrant-network-interfaces")
          ssh.exec!("sudo su -c 'cat /tmp/vagrant-network-interfaces > /etc/network/interfaces'")
        end
      end

      def enable_host_only_network(net_options)
        entry = TemplateRenderer.render('network_entry_debian', :net_options => net_options)
        vm.ssh.upload!(StringIO.new(entry), "/tmp/vagrant-network-entry")

        vm.ssh.execute do |ssh|
          ssh.exec!("sudo /sbin/ifdown eth#{net_options[:adapter]} 2> /dev/null")
          ssh.exec!("sudo su -c 'cat /tmp/vagrant-network-entry >> /etc/network/interfaces'")
          ssh.exec!("sudo /sbin/ifup eth#{net_options[:adapter]}")
        end
      end
    end
  end
end
