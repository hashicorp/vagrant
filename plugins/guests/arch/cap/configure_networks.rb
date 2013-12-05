require "tempfile"

require "vagrant/util/template_renderer"

module VagrantPlugins
  module GuestArch
    module Cap
      class ConfigureNetworks
        include Vagrant::Util

        def self.configure_networks(machine, networks)
          networks.each do |network|
            entry = TemplateRenderer.render("guests/arch/network_#{network[:type]}",
                                            :options => network)

            temp = Tempfile.new("vagrant")
            temp.binmode
            temp.write(entry)
            temp.close

            # Only consider nth line of sed's output below. There certainly is a
            # better way to do this
            snth = network[:interface] + 1

            machine.communicate.upload(temp.path, "/tmp/vagrant_network")
            machine.communicate.sudo("mv /tmp/vagrant_network /etc/netctl/eth#{network[:interface]}")

            # A hack not to rely on udev rule 80-net-name-slot.rules masking:
            # ln -sf /dev/null /etc/udev/80-net-name-slot.rules that
            # I assume this to be the most portable solution because
            # otherwise we would need to rely on the Virtual Machine implementation
            # to provide details on the configured interfaces, e.g mac address
            # to write a custom udev rule.
            machine.communicate.sudo("sed -i s/eth#{network[:interface]}/`systemctl list-units -t device | sed -n 's/.*subsystem.net-devices-\\(.*\\).device.*/\\1/p' | sed -n #{snth}p`/g /etc/netctl/eth#{network[:interface]}")
            machine.communicate.sudo("netctl start eth#{network[:interface]}")
          end
        end
      end
    end
  end
end
