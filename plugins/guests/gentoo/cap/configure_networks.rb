require "tempfile"

require_relative "../../../../lib/vagrant/util/template_renderer"

module VagrantPlugins
  module GuestGentoo
    module Cap
      class ConfigureNetworks
        include Vagrant::Util

        def self.configure_networks(machine, networks)
          comm = machine.communicate

          commands   = []
          interfaces = []

          # Remove any previous network additions to the configuration file.
          commands << "sed -i'' -e '/^#VAGRANT-BEGIN/,/^#VAGRANT-END/ d' /etc/conf.d/net"

          comm.sudo("ifconfig -a | grep -o ^[0-9a-z]* | grep -v '^lo'") do |_, stdout|
            interfaces = stdout.split("\n")
          end

          networks.each_with_index do |network, i|
            network[:device] = interfaces[network[:interface]]

            entry = TemplateRenderer.render("guests/gentoo/network_#{network[:type]}",
              options: network,
            )

            remote_path = "/tmp/vagrant-network-#{network[:device]}-#{Time.now.to_i}-#{i}"

            Tempfile.open("vagrant-gentoo-configure-networks") do |f|
              f.binmode
              f.write(entry)
              f.fsync
              f.close
              comm.upload(f.path, remote_path)
            end

            commands << <<-EOH.gsub(/^ {14}/, '')
              ln -sf /etc/init.d/net.lo /etc/init.d/net.#{network[:device]}
              /etc/init.d/net.#{network[:device]} stop || true

              cat '#{remote_path}' >> /etc/conf.d/net
              rm -f '#{remote_path}'

              /etc/init.d/net.#{network[:device]} start
            EOH
          end

          comm.sudo(commands.join("\n"))
        end
      end
    end
  end
end
