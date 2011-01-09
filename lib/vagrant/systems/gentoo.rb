module Vagrant
  module Systems
    class Gentoo < Linux
      def enable_host_only_network(net_options)
        entry = TemplateRenderer.render('network_entry_gentoo', :net_options => net_options)
        vm.ssh.upload!(StringIO.new(entry), "/tmp/vagrant-network-entry")

        vm.ssh.execute do |ssh|
          ssh.exec!("sudo ln -s /etc/init.d/net.lo /etc/init.d/net.eth#{net_options[:adapter]}")
          ssh.exec!("sudo /etc/init.d/net.eth#{net_options[:adapter]} stop 2> /dev/null")
          ssh.exec!("sudo su -c 'cat /tmp/vagrant-network-entry >> /etc/conf.d/net'")
          ssh.exec!("sudo /etc/init.d/net.eth#{net_options[:adapter]} start")
        end
      end
    end
  end
end
