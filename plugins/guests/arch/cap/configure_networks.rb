# -*- coding: utf-8 -*-
require "tempfile"

require "vagrant/util/template_renderer"

module VagrantPlugins
  module GuestArch
    module Cap
      class ConfigureNetworks
        include Vagrant::Util

        def self.configure_networks(machine, networks)
          interfaces = Array.new
          machine.communicate.sudo("ip -o -0 addr | grep -v LOOPBACK | awk '{print $2}' | sed 's/://'") do |_, result|
            interfaces = result.split("\n")
          end

          networks.each do |network|
            network[:device] = interfaces[network[:interface]]

            entry = TemplateRenderer.render("guests/arch/network_#{network[:type]}", options: network)

            temp = Tempfile.new("vagrant")
            temp.binmode
            temp.write(entry)
            temp.close

            machine.communicate.upload(temp.path, "/tmp/vagrant_network")
            machine.communicate.sudo("mv /tmp/vagrant_network /etc/netctl/#{network[:device]}")
            machine.communicate.sudo("ip link set #{network[:device]} down && netctl start #{network[:device]}")
          end
        end
      end
    end
  end
end
