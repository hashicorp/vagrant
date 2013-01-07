require 'set'
require 'tempfile'

require "vagrant"
require 'vagrant/util/template_renderer'

require Vagrant.source_root.join("plugins/guests/linux/guest")

module VagrantPlugins
  module GuestRedHat
    class Guest < VagrantPlugins::GuestLinux::Guest
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
          vm.communicate.sudo("touch #{network_scripts_dir}/ifcfg-eth#{network[:interface]}")
          vm.communicate.sudo("sed -e '/^#VAGRANT-BEGIN/,/^#VAGRANT-END/ d' #{network_scripts_dir}/ifcfg-eth#{network[:interface]} > /tmp/vagrant-ifcfg-eth#{network[:interface]}")
          vm.communicate.sudo("cat /tmp/vagrant-ifcfg-eth#{network[:interface]} > #{network_scripts_dir}/ifcfg-eth#{network[:interface]}")
          vm.communicate.sudo("rm /tmp/vagrant-ifcfg-eth#{network[:interface]}")

          # Render and upload the network entry file to a deterministic
          # temporary location.
          entry = TemplateRenderer.render("guests/redhat/network_#{network[:type]}",
                                          :options => network)

          temp = Tempfile.new("vagrant")
          temp.binmode
          temp.write(entry)
          temp.close

          vm.communicate.upload(temp.path, "/tmp/vagrant-network-entry_#{network[:interface]}")
        end

        # Bring down all the interfaces we're reconfiguring. By bringing down
        # each specifically, we avoid reconfiguring eth0 (the NAT interface) so
        # SSH never dies.
        interfaces.each do |interface|
          vm.communicate.sudo("/sbin/ifdown eth#{interface} 2> /dev/null", :error_check => false)
          vm.communicate.sudo("cat /tmp/vagrant-network-entry_#{interface} >> #{network_scripts_dir}/ifcfg-eth#{interface}")
          vm.communicate.sudo("rm /tmp/vagrant-network-entry_#{interface}")
          vm.communicate.sudo("/sbin/ifup eth#{interface} 2> /dev/null")
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
        vm.communicate.tap do |comm|
          # Only do this if the hostname is not already set
          if !comm.test("sudo hostname | grep '#{name}'")
            comm.sudo("sed -i 's/\\(HOSTNAME=\\).*/\\1#{name}/' /etc/sysconfig/network")
            comm.sudo("hostname #{name}")
            comm.sudo("sed -i 's@^\\(127[.]0[.]0[.]1[[:space:]]\\+\\)@\\1#{name} #{name.split('.')[0]} @' /etc/hosts")
          end
        end
      end
    end
  end
end
