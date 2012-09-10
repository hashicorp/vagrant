require 'set'
require 'tempfile'

require "vagrant"
require 'vagrant/util/template_renderer'

require Vagrant.source_root.join("plugins/guests/linux/guest")

module VagrantPlugins
  module GuestDebian
    class Guest < VagrantPlugins::GuestLinux::Guest
      # Make the TemplateRenderer top-level
      include Vagrant::Util

      def configure_networks(networks)
        # First, remove any previous network modifications
        # from the interface file.
        vm.communicate.sudo("sed -e '/^#VAGRANT-BEGIN/,/^#VAGRANT-END/ d' /etc/network/interfaces > /tmp/vagrant-network-interfaces")
        vm.communicate.sudo("su -c 'cat /tmp/vagrant-network-interfaces > /etc/network/interfaces'")
        vm.communicate.sudo("rm /tmp/vagrant-network-interfaces")

        # Accumulate the configurations to add to the interfaces file as
        # well as what interfaces we're actually configuring since we use that
        # later.
        interfaces = Set.new
        entries = []
        networks.each do |network|
          interfaces.add(network[:interface])
          entry = TemplateRenderer.render("guests/debian/network_#{network[:type]}",
                                          :options => network)

          entries << entry
        end

        # Perform the careful dance necessary to reconfigure
        # the network interfaces
        temp = Tempfile.new("vagrant")
        temp.binmode
        temp.write(entries.join("\n"))
        temp.close

        vm.communicate.upload(temp.path, "/tmp/vagrant-network-entry")

        # Bring down all the interfaces we're reconfiguring. By bringing down
        # each specifically, we avoid reconfiguring eth0 (the NAT interface) so
        # SSH never dies.
        interfaces.each do |interface|
          vm.communicate.sudo("/sbin/ifdown eth#{interface} 2> /dev/null")
        end

        vm.communicate.sudo("cat /tmp/vagrant-network-entry >> /etc/network/interfaces")
        vm.communicate.sudo("rm /tmp/vagrant-network-entry")

        # Bring back up each network interface, reconfigured
        interfaces.each do |interface|
          vm.communicate.sudo("/sbin/ifup eth#{interface}")
        end
      end

      def change_host_name(name)
        vm.communicate.tap do |comm|
          if !comm.test("hostname --fqdn | grep '^#{name}$' || hostname --short | grep '^#{name}$'")
            comm.sudo("sed -r -i 's/^(127[.]0[.]1[.]1[[:space:]]+).*$/\\1#{name} #{name.split('.')[0]}/' /etc/hosts")
            comm.sudo("sed -i 's/.*$/#{name.split('.')[0]}/' /etc/hostname")
            comm.sudo("hostname -F /etc/hostname")
            comm.sudo("hostname --fqdn > /etc/mailname")
          end
        end
      end
    end
  end
end
