require "tempfile"

require "vagrant/util/template_renderer"

module VagrantPlugins
  module GuestFuntoo
    module Cap
      class ConfigureNetworks
        include Vagrant::Util

        def self.configure_networks(machine, networks)
          machine.communicate.tap do |comm|
            # Configure each network interface
            networks.each do |network|
              # http://www.funtoo.org/Funtoo_Linux_Networking
              # dhcpcd generally runs on all interfaces by default
              # in the future we can change this, dhcpcd has lots of features
              # it would be nice to expose more of its capabilities...
              if not /dhcp/i.match(network[:type])
                line = "denyinterfaces eth#{network[:interface]}"
                cmd = "grep '#{line}' /etc/dhcpcd.conf; if [ $? -ne 0 ]; then echo '#{line}' >> /etc/dhcpcd.conf ;  fi"
                comm.sudo(cmd)
                ifFile = "netif.eth#{network[:interface]}"
                entry = TemplateRenderer.render("guests/funtoo/network_#{network[:type]}",
                                                 options: network)
                # Upload the entry to a temporary location
                temp = Tempfile.new("vagrant")
                temp.binmode
                temp.write(entry)
                temp.close
                comm.upload(temp.path, "/tmp/vagrant-#{ifFile}")
                comm.sudo("cp /tmp/vagrant-#{ifFile} /etc/conf.d/#{ifFile}")
                comm.sudo("chmod 0644 /etc/conf.d/#{ifFile}")
                comm.sudo("ln -fs /etc/init.d/netif.tmpl /etc/init.d/#{ifFile}")
                comm.sudo("/etc/init.d/#{ifFile} start")
              end
            end
          end
        end
      end
    end
  end
end
