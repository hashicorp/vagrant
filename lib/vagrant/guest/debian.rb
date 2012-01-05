require 'set'

require 'vagrant/util/template_renderer'

module Vagrant
  module Guest
    class Debian < Linux
      # Make the TemplateRenderer top-level
      include Vagrant::Util

      def configure_networks(networks)
        # First, remove any previous network modifications
        # from the interface file.
        vm.ssh.execute do |ssh|
          ssh.exec!("sudo sed -e '/^#VAGRANT-BEGIN/,/^#VAGRANT-END/ d' /etc/network/interfaces > /tmp/vagrant-network-interfaces")
          ssh.exec!("sudo su -c 'cat /tmp/vagrant-network-interfaces > /etc/network/interfaces'")
        end

        # Accumulate the configurations to add to the interfaces file as
        # well as what interfaces we're actually configuring since we use that
        # later.
        interfaces = Set.new
        entries = []
        networks.each do |network|
          interfaces.add(network[:interface])
          entries << TemplateRenderer.render("guests/debian/network_#{network[:type]}",
                                             :options => network)
        end

        # Perform the careful dance necessary to reconfigure
        # the network interfaces
        vm.ssh.upload!(StringIO.new(entries.join("\n")), "/tmp/vagrant-network-entry")

        vm.ssh.execute do |ssh|
          # Bring down all the interfaces we're reconfiguring. By bringing down
          # each specifically, we avoid reconfiguring eth0 (the NAT interface) so
          # SSH never dies.
          interfaces.each do |interface|
            ssh.exec!("sudo /sbin/ifdown eth#{interface} 2> /dev/null")
          end

          ssh.exec!("sudo su -c 'cat /tmp/vagrant-network-entry >> /etc/network/interfaces'")

          # Bring back up each network interface, reconfigured
          interfaces.each do |interface|
            ssh.exec!("sudo /sbin/ifup eth#{interface}")
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
