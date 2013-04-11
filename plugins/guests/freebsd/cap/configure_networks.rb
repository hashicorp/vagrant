require "tempfile"

require "vagrant/util/template_renderer"

module VagrantPlugins
  module GuestFreeBSD
    module Cap
      class ConfigureNetworks
        include Vagrant::Util

        def self.configure_networks(machine, networks)
          # Remove any previous network additions to the configuration file.
          machine.communicate.sudo("sed -i '' -e '/^#VAGRANT-BEGIN/,/^#VAGRANT-END/ d' /etc/rc.conf")

          networks.each do |network|
            entry = TemplateRenderer.render("guests/freebsd/network_#{network[:type]}",
                                            :options => network)

            # Write the entry to a temporary location
            temp = Tempfile.new("vagrant")
            temp.binmode
            temp.write(entry)
            temp.close

            machine.communicate.upload(temp.path, "/tmp/vagrant-network-entry")
            machine.communicate.sudo("su -m root -c 'cat /tmp/vagrant-network-entry >> /etc/rc.conf'")
            machine.communicate.sudo("rm /tmp/vagrant-network-entry")

            if network[:type].to_sym == :static
              machine.communicate.sudo("ifconfig em#{network[:interface]} inet #{network[:ip]} netmask #{network[:netmask]}")
            elsif network[:type].to_sym == :dhcp
              machine.communicate.sudo("dhclient em#{network[:interface]}")
            end
          end
        end
      end
    end
  end
end
