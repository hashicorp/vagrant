# -*- coding: utf-8 -*-
require_relative "../../../../lib/vagrant/util/template_renderer"
require_relative "../../../../lib/vagrant/util/tempfile"

module VagrantPlugins
  module GuestArch
    module Cap
      class ConfigureNetworks
        include Vagrant::Util

        def self.configure_networks(machine, networks)
          tempfiles  = []
          interfaces = []

          machine.communicate.sudo("ip -o -0 addr | grep -v LOOPBACK | awk '{print $2}' | sed 's/://'") do |_, result|
            interfaces = result.split("\n")
          end

          networks.each.with_index do |network, i|
            network[:device] = interfaces[network[:interface]]

            entry = TemplateRenderer.render("guests/arch/network_#{network[:type]}",
              options: network)

            remote_path = "/tmp/vagrant-network-#{Time.now.to_i}-#{i}"

            Tempfile.create("arch-configure-networks") do |f|
              f.write(entry)
              f.fsync
              f.close
              machine.communicate.upload(f.path, remote_path)
            end

            machine.communicate.sudo("mv #{remote_path} /etc/netctl/#{network[:device]}")
            machine.communicate.sudo("ip link set #{network[:device]} down && netctl restart #{network[:device]} && netctl enable #{network[:device]}")
          end
        end
      end
    end
  end
end
