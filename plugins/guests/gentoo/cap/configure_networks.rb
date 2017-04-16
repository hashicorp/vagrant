require "tempfile"
require "ipaddr"

require_relative "../../../../lib/vagrant/util/template_renderer"

module VagrantPlugins
  module GuestGentoo
    module Cap
      class ConfigureNetworks
        include Vagrant::Util

        def self.configure_networks(machine, networks)
          comm = machine.communicate

          commands   = []
          interfaces = machine.guest.capability(:network_interfaces, "/bin/ip")

          networks.map! { |n| n[:device] = interfaces[n[:interface]]; n }

          if comm.test('[[ `systemctl` =~ -\.mount ]]')
            # Configure networking for Systemd

            # convert netmasks to CIDR by converting to a binary string and counting the '1's
            networks.map! { |n| n[:netmask] = IPAddr.new(n[:netmask]).to_i.to_s(2).count("1"); n }

            # glob networks by device, so that we can write one file per device
            # (result is hash[devicename] = [net, net, net...])
            networks = networks.map { |n| [n[:device], n] }.reduce({}) { |h, (k, v)| (h[k] ||= []) << v; h }

            # Write one .network file out for each device
            networks.each_pair do |device_name, device_networks|
              entry = TemplateRenderer.render('guests/gentoo/network_systemd', networks: device_networks)

              filename = "50_vagrant_#{device_name}.network"
              tmpfile = "/tmp/#{filename}"
              destfile = "/etc/systemd/network/#{filename}"

              Tempfile.open('vagrant-gentoo-configure-networks') do |f|
                f.binmode
                f.write(entry)
                f.fsync
                f.close
                comm.upload(f.path, tmpfile)
              end

              commands << "mv #{tmpfile} #{destfile} && chmod 644 #{destfile}"
            end

            # tell systemd to reload the networking config
            commands << 'systemctl daemon-reload && systemctl restart systemd-networkd.service'
          else
            # Configure networking for OpenRC

            # Remove any previous network additions to the configuration file.
            commands << "sed -i'' -e '/^#VAGRANT-BEGIN/,/^#VAGRANT-END/ d' /etc/conf.d/net"

            networks.each_with_index do |network, i|
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
          end

          comm.sudo(commands.join("\n"))
        end
      end
    end
  end
end
