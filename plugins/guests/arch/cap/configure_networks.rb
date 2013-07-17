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

            machine.communicate.upload(temp.path, "/tmp/vagrant_network")
            machine.communicate.sudo("ln -sf /dev/null /etc/udev/rules.d/80-net-name-slot.rules")
            machine.communicate.sudo("mv /tmp/vagrant_network /etc/netctl/eth#{network[:interface]}")
            machine.communicate.sudo("netctl start eth#{network[:interface]}")
          end
        end
      end
    end
  end
end
