require "ipaddr"
require "socket"
require "tempfile"

require_relative "../../../../lib/vagrant/util/template_renderer"

module VagrantPlugins
  module GuestArch
    module Cap
      class ConfigureNetworks
        include Vagrant::Util

        def self.configure_networks(machine, networks)
          comm = machine.communicate
          commands = []

          interfaces = machine.guest.capability(:network_interfaces)
          networks.each.with_index do |network, i|
            network[:device] = interfaces[network[:interface]]

            # Arch expects netmasks to be in the "24" or "64", but users may
            # specify IPV4 netmasks like "255.255.255.0". This magic converts
            # the netmask to the proper value.
            if network[:netmask] && network[:netmask].to_s.include?(".")
              network[:netmask] = (32-Math.log2((IPAddr.new(network[:netmask], Socket::AF_INET).to_i^0xffffffff)+1)).to_i
            end

            entry = TemplateRenderer.render("guests/arch/network_#{network[:type]}",
              options: network,
            )

            remote_path = "/tmp/vagrant-network-#{network[:device]}-#{Time.now.to_i}-#{i}"

            Tempfile.open("vagrant-arch-configure-networks") do |f|
              f.binmode
              f.write(entry)
              f.fsync
              f.close
              comm.upload(f.path, remote_path)
            end

            commands << <<-EOH.gsub(/^ {14}/, '').rstrip
              # Configure #{network[:device]}
              mv '#{remote_path}' '/etc/netctl/#{network[:device]}' &&
              ip link set '#{network[:device]}' down &&
              netctl restart '#{network[:device]}' &&
              netctl enable '#{network[:device]}'
            EOH
          end

          # Run all the network modification commands in one communicator call.
          comm.sudo(commands.join(" && \n"))
        end
      end
    end
  end
end
