module Vagrant
  module Systems
    class Redhat < Linux
      def prepare_host_only_network(net_options)
        # Remove any previous host only network additions to the
        # interface file.
        vm.ssh.execute do |ssh|
          # Clear out any previous entries
          ssh.exec!("sudo sed -e '/^#VAGRANT-BEGIN/,/^#VAGRANT-END/ d' /etc/sysconfig/network-scripts/ifcfg-eth#{net_options[:adapter]} > /tmp/vagrant-ifcfg-eth#{net_options[:adapter]}")
          ssh.exec!("sudo su -c 'cat /tmp/vagrant-ifcfg-eth#{net_options[:adapter]} > /etc/sysconfig/network-scripts/ifcfg-eth#{net_options[:adapter]}'")
        end
      end

      def enable_host_only_network(net_options)
        entry = TemplateRenderer.render('network_entry_redhat', :net_options => net_options)

        vm.ssh.upload!(StringIO.new(entry), "/tmp/vagrant-network-entry")

        vm.ssh.execute do |ssh|
          interface_up = ssh.test?("/sbin/ifconfig eth#{net_options[:adapter]} | grep 'inet addr:'")
          ssh.exec!("sudo /sbin/ifdown eth#{net_options[:adapter]} 2> /dev/null") if interface_up
          ssh.exec!("sudo su -c 'cat /tmp/vagrant-network-entry >> /etc/sysconfig/network-scripts/ifcfg-eth#{net_options[:adapter]}'")
          ssh.exec!("sudo /sbin/ifup eth#{net_options[:adapter]}")
        end
      end

      def change_host_name(name)
        vm.ssh.execute do |ssh|
          host_name_already_set = ssh.test?("sudo hostname | grep '#{name}'")
          ssh.exec!("sudo sed -i 's/\\(HOSTNAME=\\).*/\\1#{name}/' /etc/sysconfig/network") unless host_name_already_set
          ssh.exec!("sudo hostname #{name}") unless host_name_already_set
        end
      end

    end
  end
end



