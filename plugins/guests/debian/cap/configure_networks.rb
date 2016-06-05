require "tempfile"

require_relative "../../../../lib/vagrant/util/template_renderer"

module VagrantPlugins
  module GuestDebian
    module Cap
      class ConfigureNetworks
        include Vagrant::Util

        def self.configure_networks(machine, networks)
          comm = machine.communicate

          interfaces = {}
          entries    = []

          # Accumulate the configurations to add to the interfaces file as
          # well as what interfaces we're actually configuring since we use that
          # later.
          networks.each do |network|
            interfaces[network[:interface]] = true

            entry = TemplateRenderer.render("guests/debian/network_#{network[:type]}",
              options: network,
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

          commands = []

          # Bring down all the interfaces we're reconfiguring. By bringing down
          # each specifically, we avoid reconfiguring eth0 (the NAT interface)
          # so SSH never dies.
          interfaces.each do |interface, _|
            # Ubuntu 16.04+ returns an error when downing an interface that
            # does not exist. The `|| true` preserves the behavior that older
            # Ubuntu versions exhibit and Vagrant expects (GH-7155)
            commands << "/sbin/ifdown 'eth#{interface}' 2> /dev/null || true"
            commands << "/sbin/ip addr flush dev 'eth#{interface}' 2> /dev/null"
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
          interfaces.each do |interface, _|
            commands << "/sbin/ifup 'eth#{interface}'"
          end

          # Run all the commands in one session to prevent partial configuration
          # due to a severed network.
          comm.sudo(commands.join("\n"))
        end
      end
    end
  end
end
