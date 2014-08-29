require "tempfile"

require "vagrant/util/template_renderer"

module VagrantPlugins
  module GuestNetBSD
    module Cap
      class ConfigureNetworks
        include Vagrant::Util

        def self.configure_networks(machine, networks)

          # setup a new rc.conf file
          newrcconf = "/tmp/rc.conf.vagrant_configurenetworks"
          machine.communicate.sudo("sed -e '/^#VAGRANT-BEGIN/,/^#VAGRANT-END/ d' /etc/rc.conf > #{newrcconf}")

          networks.each do |network|

            # create an interface configuration file fragment
            entry = TemplateRenderer.render("guests/netbsd/network_#{network[:type]}",
                                            options: network)

            temp = Tempfile.new("vagrant")
            temp.binmode
            temp.write(entry)
            temp.close

            # upload it and append it to the new rc.conf file
            machine.communicate.upload(temp.path, "/tmp/vagrant-network-entry")
            machine.communicate.sudo("cat /tmp/vagrant-network-entry >> #{newrcconf}")
            machine.communicate.sudo("rm -f /tmp/vagrant-network-entry")

            ifname = "wm#{network[:interface]}"
            # remove old configuration
            machine.communicate.sudo("/sbin/dhcpcd -x #{ifname}", { error_check: false })
            machine.communicate.sudo("/sbin/ifconfig #{ifname} inet delete", { error_check: false })

            # live new configuration
            if network[:type].to_sym == :static
              machine.communicate.sudo("/sbin/ifconfig #{ifname} media autoselect up;/sbin/ifconfig #{ifname} inet #{network[:ip]} netmask #{network[:netmask]}")
            elsif network[:type].to_sym == :dhcp
              machine.communicate.sudo("/sbin/dhcpcd -n -q #{ifname}")
            end
          end

          # install new rc.conf
          machine.communicate.sudo("install -c -o 0 -g 0 -m 644 #{newrcconf} /etc/rc.conf")

        end
      end
    end
  end
end
