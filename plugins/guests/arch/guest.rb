require 'set'
require 'tempfile'

require 'vagrant/util/template_renderer'

module VagrantPlugins
  module GuestArch
    class Guest < VagrantPlugins::GuestLinux::Guest
      # Make the TemplateRenderer top-level
      include Vagrant::Util

      def change_host_name(name)
        # Only do this if the hostname is not already set
        if !vm.channel.test("sudo hostname | grep '#{name}'")
          vm.channel.sudo("sed -i 's/\\(HOSTNAME=\\).*/\\1#{name}/' /etc/rc.conf")
          vm.channel.sudo("hostname #{name}")
          vm.channel.sudo("sed -i 's@^\\(127[.]0[.]0[.]1[[:space:]]\\+\\)@\\1#{name} @' /etc/hosts")
        end
      end

      def configure_networks(networks)
        # Remove previous Vagrant-managed network interfaces
        vm.channel.sudo("sed -e '/^#VAGRANT-BEGIN/,/^#VAGRANT-END/ d' /etc/rc.conf > /tmp/vagrant-network-interfaces")
        vm.channel.sudo("cat /tmp/vagrant-network-interfaces > /etc/rc.conf")
        vm.channel.sudo("rm /tmp/vagrant-network-interfaces")

        # Configure the network interfaces
        interfaces = Set.new
        entries = []
        networks.each do |network|
          interfaces.add(network[:interface])
          entry = TemplateRenderer.render("guests/arch/network_#{network[:type]}",
                                          :options => network)

          entries << entry
        end

        # Perform the careful dance necessary to reconfigure
        # the network interfaces
        temp = Tempfile.new("vagrant")
        temp.binmode
        temp.write(entries.join("\n"))
        temp.close

        vm.channel.upload(temp.path, "/tmp/vagrant-network-entry")

        # Reconfigure the network interfaces
        vm.channel.sudo("cat /tmp/vagrant-network-entry >> /etc/rc.conf")
        vm.channel.sudo("rm /tmp/vagrant-network-entry")
        vm.channel.sudo("/etc/rc.d/network restart")

        interfaces.each do |interface|
          vm.channel.sudo("dhcpcd -k eth#{interface} && dhcpcd eth#{interface} && sleep 3")
        end
      end
    end
  end
end
