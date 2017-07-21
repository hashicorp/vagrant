require "tempfile"

require_relative "../../../../lib/vagrant/util/template_renderer"

module VagrantPlugins
  module GuestFreeBSD
    module Cap
      class ConfigureNetworks
        include Vagrant::Util

        def self.configure_networks(machine, networks)
          options = { shell: "sh" }
          comm = machine.communicate

          commands   = []
          interfaces = []

          # Remove any previous network additions to the configuration file.
          commands << "sed -i'' -e '/^#VAGRANT-BEGIN/,/^#VAGRANT-END/ d' /etc/rc.conf"

          comm.sudo("ifconfig -a | grep -o '^[0-9a-z]*' | grep -v '^lo'", options) do |_, stdout|
            interfaces = stdout.split("\n")
          end

          networks.each.with_index do |network, i|
            network[:device] = interfaces[network[:interface]]

            entry = TemplateRenderer.render("guests/freebsd/network_#{network[:type]}",
              options: network,
            )

            remote_path = "/tmp/vagrant-network-#{network[:device]}-#{Time.now.to_i}-#{i}"

            Tempfile.open("vagrant-freebsd-configure-networks") do |f|
              f.binmode
              f.write(entry)
              f.fsync
              f.close
              comm.upload(f.path, remote_path)
            end

            commands << <<-EOH.gsub(/^ {14}/, '')
              cat '#{remote_path}' >> /etc/rc.conf
              rm -f '#{remote_path}'
            EOH

            # If the network is DHCP, then we have to start the dhclient, unless
            # it is already running. See GH-5852 for more information
            if network[:type].to_sym == :dhcp
              file = "/var/run/dhclient.#{network[:device]}.pid"
              commands << <<-EOH.gsub(/^ {16}/, '')
                if ! test -f '#{file}' || ! kill -0 $(cat '#{file}'); then
                  dhclient '#{network[:device]}'
                fi
              EOH
            end

            # For some reason, this returns status 1... every time
            commands << "/etc/rc.d/netif restart '#{network[:device]}' || true"
          end

          comm.sudo(commands.join("\n"), options)
        end
      end
    end
  end
end
