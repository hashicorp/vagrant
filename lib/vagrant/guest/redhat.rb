require 'set'

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

        # Since redhat/centos uses a single file for each interface,
        # we must loop through for each network assigned
        networks.each do |network|
          interfaces.add(network[:interface])

          # First, remove any previous network modifications
          # from the interface file.
          vm.ssh.execute do |ssh|
            ssh.exec!("sudo touch #{network_scripts_dir}/ifcfg-eth#{network[:interface]}")
            ssh.exec!("sudo sed -e '/^#VAGRANT-BEGIN/,/^#VAGRANT-END/ d' #{network_scripts_dir}/ifcfg-eth#{network[:interface]} > /tmp/vagrant-ifcfg-eth#{network[:interface]}")
            ssh.exec!("sudo su -c 'cat /tmp/vagrant-ifcfg-eth#{network[:interface]} > #{network_scripts_dir}/ifcfg-eth#{network[:interface]}'")
          end

          entry = ""
          entry << TemplateRenderer.render("guests/redhat/network_#{network[:type]}",
                                               :options => network)

          # Perform the careful dance necessary to to reconfigure
          # the network interfaces
          vm.ssh.upload!(StringIO.new(entry), "/tmp/vagrant-network-entry_#{network[:interface]}")
        end

        vm.ssh.execute do |ssh|
          # Bring down all the interfaces we're reconfiguring. By bringing down
          # each specifically, we avoid reconfiguring eth0 (the NAT interface) so
          # SSH never dies.
          interfaces.each do |interface|
            ssh.exec!("sudo /sbin/ifdown eth#{interface} 2> /dev/null")
            ssh.exec!("sudo su -c 'cat /tmp/vagrant-network-entry_#{interface} >> #{network_scripts_dir}/ifcfg-eth#{interface}'")
            # Bring back up each network interface, reconfigured
            ssh.exec!("sudo /sbin/ifup eth#{interface}")
          end
        end
      end

      def prepare_bridged_networks(networks)
        # Remove any previous bridged network additions from the
        # interface file.
        vm.ssh.execute do |ssh|
          networks.each do |network|
            # Clear out any previous entries
            ssh.exec!("sudo touch #{network_scripts_dir}/ifcfg-eth#{network[:adapter]}")
            ssh.exec!("sudo sed -e '/^#VAGRANT-BEGIN-BRIDGED/,/^#VAGRANT-END-BRIDGED/ d' #{network_scripts_dir}/ifcfg-eth#{network[:adapter]} > /tmp/vagrant-ifcfg-eth#{network[:adapter]}")
            ssh.exec!("sudo su -c 'cat /tmp/vagrant-ifcfg-eth#{network[:adapter]} > #{network_scripts_dir}/ifcfg-eth#{network[:adapter]}'")
          end
        end
      end

      def enable_bridged_networks(networks)
        entry = TemplateRenderer.render('guests/redhat/network_bridged',
                                        :networks => networks)

        vm.ssh.upload!(StringIO.new(entry), "/tmp/vagrant-network-entry")

        vm.ssh.execute do |ssh|
          networks.each do |network|
            interface_up = ssh.test?("/sbin/ifconfig eth#{network[:adapter]} | grep 'inet addr:'")
            ssh.exec!("sudo /sbin/ifdown eth#{network[:adapter]} 2> /dev/null") if interface_up
            ssh.exec!("sudo su -c 'cat /tmp/vagrant-network-entry >> #{network_scripts_dir}/ifcfg-eth#{network[:adapter]}'")
            ssh.exec!("sudo /sbin/ifup eth#{network[:adapter]}")
          end
        end
      end

      # The path to the directory with the network configuration scripts.
      # This is pulled out into its own directory since there are other
      # operationg systems (SuSE) which behave similarly but with a different
      # path to the network scripts.
      def network_scripts_dir
        '/etc/sysconfig/network-scripts'
      end

      def change_host_name(name)
        vm.ssh.execute do |ssh|
          # Only do this if the hostname is not already set
          if !ssh.test?("sudo hostname | grep '#{name}'")
            ssh.exec!("sudo sed -i 's/\\(HOSTNAME=\\).*/\\1#{name}/' /etc/sysconfig/network")
            ssh.exec!("sudo hostname #{name}")
            ssh.exec!("sudo sed -i 's@^\\(127[.]0[.]0[.]1[[:space:]]\\+\\)@\\1#{name} #{name.split('.')[0]} @' /etc/hosts")
          end
        end
      end
    end
  end
end
