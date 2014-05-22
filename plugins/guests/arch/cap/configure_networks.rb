# -*- coding: utf-8 -*-
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
                                            options: network)

            temp = Tempfile.new("vagrant")
            temp.binmode
            temp.write(entry)
            temp.close

            machine.communicate.upload(temp.path, "/tmp/vagrant_network")
            machine.communicate.sudo("ln -sf /dev/null /etc/udev/rules.d/80-net-name-slot.rules")
            machine.communicate.sudo("udevadm control --reload")
            machine.communicate.sudo("mv /tmp/vagrant_network /etc/netctl/eth#{network[:interface]}")

            # Only consider nth line of sed's output below. There's always an
            # offset of two lines in the below sed command given the current
            # interface number -> 1: lo, 2: nat device,
            snth = network[:interface] + 2

            # A hack not to rely on udev rule 80-net-name-slot.rules masking
            # (ln -sf /dev/null /etc/udev/80-net-name-slot.rules).
            # I assume this to be the most portable solution because
            # otherwise we would need to rely on the Virtual Machine implementation
            # to provide details on the configured interfaces, e.g mac address
            # to write a custom udev rule. Templating the netcfg files and
            # replacing the correct interface name within ruby seems more
            # complicted too (I'm far from being a ruby expert though).
            machine.communicate.sudo("sed -i \"s/eth#{network[:interface]}/`ip link | sed -n 's/.*:\\s\\(.*\\): <.*/\\1/p' | sed -n #{snth}p`/g\" /etc/netctl/eth#{network[:interface]}")
            machine.communicate.sudo("ip link set eth#{network[:interface]} down")
            machine.communicate.sudo("netctl start eth#{network[:interface]}")
          end
        end
      end
    end
  end
end
