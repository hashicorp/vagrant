require "tempfile"

require_relative "../../../../lib/vagrant/util/template_renderer"

module VagrantPlugins
  module GuestSlackware
    module Cap
      class ConfigureNetworks
        include Vagrant::Util

        def self.configure_networks(machine, networks)
          comm = machine.communicate

          commands   = []
          interfaces = machine.guest.capability(:network_interfaces)

          # Remove any previous configuration
          commands << "sed -i'' -e '/^#VAGRANT-BEGIN/,/^#VAGRANT-END/ d' /etc/rc.d/rc.inet1.conf"

          networks.each.with_index do |network, i|
            network[:device] = interfaces[network[:interface]]

            entry = TemplateRenderer.render("guests/slackware/network_#{network[:type]}",
              i: i+1,
              options: network,
            )

            remote_path = "/tmp/vagrant-network-#{network[:device]}-#{Time.now}-#{i}"
            Tempfile.open("vagrant-slackware-configure-networks") do |f|
              f.binmode
              f.write(entry)
              f.fsync
              f.close
              comm.upload(f.path, remote_path)
            end

            commands << "cat '#{remote_path}' >> /etc/rc.d/rc.inet1.conf"
          end

          # Restart networking
          commands << "/etc/rc.d/rc.inet1"

          comm.sudo(commands.join("\n"))
        end
      end
    end
  end
end
