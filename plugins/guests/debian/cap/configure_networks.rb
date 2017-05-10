require "tempfile"

require_relative "../../../../lib/vagrant/util/template_renderer"

module VagrantPlugins
  module GuestDebian
    module Cap
      class ConfigureNetworks
        include Vagrant::Util

        def self.configure_networks(machine, networks)
          comm = machine.communicate

          commands   = []
          entries    = []
          interfaces = machine.guest.capability(:network_interfaces)

          root_device = interfaces.first
          networks.each do |network|
            network[:device] = interfaces[network[:interface]]

            entry = TemplateRenderer.render("guests/debian/network_#{network[:type]}",
              options: network.merge(:root_device => root_device),
            )
            entries << entry
          end

          Tempfile.open("vagrant-debian-configure-networks") do |f|
            f.binmode
            f.write(entries.join("\n"))
            f.fsync
            f.close
            comm.upload(f.path, "/tmp/vagrant-network-entry")
          end

          networks.each do |network|
            # Ubuntu 16.04+ returns an error when downing an interface that
            # does not exist. The `|| true` preserves the behavior that older
            # Ubuntu versions exhibit and Vagrant expects (GH-7155)
            commands << "/sbin/ifdown '#{network[:device]}' || true"
            commands << "/sbin/ip addr flush dev '#{network[:device]}'"
          end

          # Reconfigure /etc/network/interfaces.
          commands << <<-EOH.gsub(/^ {12}/, "")
            # Remove any previous network modifications from the interfaces file
            sed -e '/^#VAGRANT-BEGIN/,$ d' /etc/network/interfaces > /tmp/vagrant-network-interfaces.pre
            sed -ne '/^#VAGRANT-END/,$ p' /etc/network/interfaces | tac | sed -e '/^#VAGRANT-END/,$ d' | tac > /tmp/vagrant-network-interfaces.post

            cat \\
              /tmp/vagrant-network-interfaces.pre \\
              /tmp/vagrant-network-entry \\
              /tmp/vagrant-network-interfaces.post \\
              > /etc/network/interfaces

            rm -f /tmp/vagrant-network-interfaces.pre
            rm -f /tmp/vagrant-network-entry
            rm -f /tmp/vagrant-network-interfaces.post
          EOH

          # Bring back up each network interface, reconfigured.
          networks.each do |network|
            commands << "/sbin/ifup '#{network[:device]}'"
          end

          # Run all the commands in one session to prevent partial configuration
          # due to a severed network.
          comm.sudo(commands.join("\n"))
        end
      end
    end
  end
end
