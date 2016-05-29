require_relative "../../../../lib/vagrant/util/template_renderer"
require_relative "../../../../lib/vagrant/util/tempfile"

module VagrantPlugins
  module GuestGentoo
    module Cap
      class ConfigureNetworks
        include Vagrant::Util

        def self.configure_networks(machine, networks)
          machine.communicate.tap do |comm|
            # Remove any previous host only network additions to the interface file
            comm.sudo("sed -e '/^#VAGRANT-BEGIN/,/^#VAGRANT-END/ d' /etc/conf.d/net > /tmp/vagrant-network-interfaces")
            comm.sudo("cat /tmp/vagrant-network-interfaces > /etc/conf.d/net")
            comm.sudo("rm -f /tmp/vagrant-network-interfaces")

            # Configure each network interface
            networks.each do |network|
              entry = TemplateRenderer.render("guests/gentoo/network_#{network[:type]}",
                                              options: network)

              # Upload the entry to a temporary location
              Tempfile.create("gentoo-configure-networks") do |f|
                f.write(entry)
                f.fsync
                f.close
                comm.upload(f.path, "/tmp/vagrant-network-entry")
              end

              # Configure the interface
              comm.sudo("ln -fs /etc/init.d/net.lo /etc/init.d/net.eth#{network[:interface]}")
              comm.sudo("/etc/init.d/net.eth#{network[:interface]} stop 2> /dev/null")
              comm.sudo("cat /tmp/vagrant-network-entry >> /etc/conf.d/net")
              comm.sudo("rm -f /tmp/vagrant-network-entry")
              comm.sudo("/etc/init.d/net.eth#{network[:interface]} start")
            end
          end
        end
      end
    end
  end
end
