require 'set'
require 'tempfile'

require 'vagrant/util/template_renderer'

module Vagrant
  module Guest
    class Redhat < Linux
      # Make the TemplateRenderer top-level
      include Vagrant::Util

      def configure_networks(networks)
        # Accumulate the configurations to add to the interfaces file as
        # well as what interfaces we're actually configuring since we use that
        # later.
        interfaces = Set.new
        networks.each do |network|
          interfaces.add(network[:interface])

          # Remove any previous vagrant configuration in this network interface's
          # configuration files.
          vm.channel.sudo("touch #{network_scripts_dir}/ifcfg-eth#{network[:interface]}")
          vm.channel.sudo("sed -e '/^#VAGRANT-BEGIN/,/^#VAGRANT-END/ d' #{network_scripts_dir}/ifcfg-eth#{network[:interface]} > /tmp/vagrant-ifcfg-eth#{network[:interface]}")
          vm.channel.sudo("cat /tmp/vagrant-ifcfg-eth#{network[:interface]} > #{network_scripts_dir}/ifcfg-eth#{network[:interface]}")

          # Render and upload the network entry file to a deterministic
          # temporary location.
          entry = TemplateRenderer.render("guests/redhat/network_#{network[:type]}",
                                          :options => network)

          temp = Tempfile.new("vagrant")
          temp.write(entry)
          temp.close

          vm.channel.upload(temp.path, "/tmp/vagrant-network-entry_#{network[:interface]}")
        end

        # Bring down all the interfaces we're reconfiguring. By bringing down
        # each specifically, we avoid reconfiguring eth0 (the NAT interface) so
        # SSH never dies.
        interfaces.each do |interface|
          vm.channel.sudo("/sbin/ifconfig eth#{interface} down 2> /dev/null")
          vm.channel.sudo("cat /tmp/vagrant-network-entry_#{interface} >> #{network_scripts_dir}/ifcfg-eth#{interface}")
          vm.channel.sudo("/sbin/ifconfig eth#{interface} up 2> /dev/null")
        end
      end

      # The path to the directory with the network configuration scripts.
      # This is pulled out into its own directory since there are other
      # operating systems (SuSE) which behave similarly but with a different
      # path to the network scripts.
      def network_scripts_dir
        '/etc/sysconfig/network-scripts'
      end

      def change_host_name(name)
        # Only do this if the hostname is not already set
        if !vm.channel.test("sudo hostname | grep '#{name}'")
          vm.channel.sudo("sed -i 's/\\(HOSTNAME=\\).*/\\1#{name}/' /etc/sysconfig/network")
          vm.channel.sudo("hostname #{name}")
          vm.channel.sudo("sed -i 's@^\\(127[.]0[.]0[.]1[[:space:]]\\+\\)@\\1#{name} #{name.split('.')[0]} @' /etc/hosts")
        end
      end
    end
  end
end
