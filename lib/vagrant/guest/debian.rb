module Vagrant
  module Guest
    class Debian < Linux
      def prepare_host_only_network(net_options=nil)
        # Remove any previous host only network additions to the interface file.
        vm.ssh.execute do |ssh|
          ssh.exec!("sudo sed -e '/^#VAGRANT-BEGIN-HOSTONLY/,/^#VAGRANT-END-HOSTONLY/ d' /etc/network/interfaces > /tmp/vagrant-network-interfaces")
          ssh.exec!("sudo su -c 'cat /tmp/vagrant-network-interfaces > /etc/network/interfaces'")
        end
      end

      def enable_host_only_network(net_options)
        entry = TemplateRenderer.render('guests/debian/network_hostonly',
                                        :net_options => net_options)
        vm.ssh.upload!(StringIO.new(entry), "/tmp/vagrant-network-entry")

        vm.ssh.execute do |ssh|
          ssh.exec!("sudo /sbin/ifdown eth#{net_options[:adapter]} 2> /dev/null")
          ssh.exec!("sudo su -c 'cat /tmp/vagrant-network-entry >> /etc/network/interfaces'")
          ssh.exec!("sudo /sbin/ifup eth#{net_options[:adapter]}")
        end
      end

      def prepare_bridged_networks(networks)
        # Remove any previous bridged network additions to the interface file.
        vm.ssh.execute do |ssh|
          ssh.exec!("sudo sed -e '/^#VAGRANT-BEGIN-BRIDGED/,/^#VAGRANT-END-BRIDGED/ d' /etc/network/interfaces > /tmp/vagrant-network-interfaces")
          ssh.exec!("sudo su -c 'cat /tmp/vagrant-network-interfaces > /etc/network/interfaces'")
        end
      end

      def enable_bridged_networks(networks)
        entry = TemplateRenderer.render('guests/debian/network_bridged',
                                        :networks => networks)

        vm.ssh.upload!(StringIO.new(entry), "/tmp/vagrant-network-entry")

        vm.ssh.execute do |ssh|
          networks.each do |network|
            ssh.exec!("sudo /sbin/ifdown eth#{network[:adapter]} 2> /dev/null")
          end

          ssh.exec!("sudo su -c 'cat /tmp/vagrant-network-entry >> /etc/network/interfaces'")

          networks.each do |network|
            ssh.exec!("sudo /sbin/ifup eth#{network[:adapter]}")
          end
        end
      end

      def change_host_name(name)
        vm.ssh.execute do |ssh|
          if !ssh.test?("sudo hostname | grep '#{name}'")
            ssh.exec!("sudo sed -i 's@^\\(127[.]0[.]1[.]1[[:space:]]\\+\\)@\\1#{name} #{name.split('.')[0]} @' /etc/hosts")
            ssh.exec!("sudo sed -i 's/.*$/#{name}/' /etc/hostname")
            ssh.exec!("sudo hostname -F /etc/hostname")
          end
        end
      end
    end
  end
end
