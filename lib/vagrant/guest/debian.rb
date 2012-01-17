require 'set'
require 'tempfile'

require 'vagrant/util/template_renderer'

module Vagrant
  module Guest
    class Debian < Linux
      # Make the TemplateRenderer top-level
      include Vagrant::Util

      def configure_networks(networks)
        # First, remove any previous network modifications
        # from the interface file.
        vm.channel.sudo("sed -e '/^#VAGRANT-BEGIN/,/^#VAGRANT-END/ d' /etc/network/interfaces > /tmp/vagrant-network-interfaces")
        vm.channel.sudo("su -c 'cat /tmp/vagrant-network-interfaces > /etc/network/interfaces'")

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
        temp = Tempfile.new("vagrant")
        temp.write(entries.join("\n"))
        temp.close

        vm.channel.upload(temp.path, "/tmp/vagrant-network-entry")

        # Bring down all the interfaces we're reconfiguring. By bringing down
        # each specifically, we avoid reconfiguring eth0 (the NAT interface) so
        # SSH never dies.
        interfaces.each do |interface|
          vm.channel.sudo("/sbin/ifdown eth#{interface} 2> /dev/null")
        end

        vm.channel.sudo("cat /tmp/vagrant-network-entry >> /etc/network/interfaces")

        # Bring back up each network interface, reconfigured
        interfaces.each do |interface|
          vm.channel.sudo("/sbin/ifup eth#{interface}")
        end
      end

      def change_host_name(name)
        if !vm.channel.test("hostname --fqdn | grep '^#{name}$' || hostname --short | grep '^#{name}$'")
          vm.channel.sudo("sed -r -i 's/^(127[.]0[.]1[.]1[[:space:]]+).*$/\\1#{name} #{name.split('.')[0]}/' /etc/hosts")
          vm.channel.sudo("sed -i 's/.*$/#{name.split('.')[0]}/' /etc/hostname")
          vm.channel.sudo("hostname -F /etc/hostname")
        end
      end
    end
  end
end
