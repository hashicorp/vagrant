module Vagrant
  module Guest
    class Gentoo < Linux
      def prepare_host_only_network(net_options=nil)
        # Remove any previous host only network additions to the
        # interface file.
        vm.ssh.execute do |ssh|
          ssh.exec!("sudo sed -e '/^#VAGRANT-BEGIN-HOSTONLY/,/^#VAGRANT-END-HOSTONLY/ d' /etc/conf.d/net > /tmp/vagrant-network-interfaces")
          ssh.exec!("sudo su -c 'cat /tmp/vagrant-network-interfaces > /etc/conf.d/net'")
        end
      end

      def enable_host_only_network(net_options)
        entry = TemplateRenderer.render('guests/gentoo/network_hostonly',
                                        :net_options => net_options)
        vm.ssh.upload!(StringIO.new(entry), "/tmp/vagrant-network-entry")

        vm.ssh.execute do |ssh|
          ssh.exec!("sudo ln -fs /etc/init.d/net.lo /etc/init.d/net.eth#{net_options[:adapter]}")
          ssh.exec!("sudo /etc/init.d/net.eth#{net_options[:adapter]} stop 2> /dev/null")
          ssh.exec!("sudo su -c 'cat /tmp/vagrant-network-entry >> /etc/conf.d/net'")
          ssh.exec!("sudo /etc/init.d/net.eth#{net_options[:adapter]} start")
        end
      end
    end
  end
end
