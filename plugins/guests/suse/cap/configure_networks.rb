require "tempfile"

require_relative "../../../../lib/vagrant/util/template_renderer"

module VagrantPlugins
  module GuestSUSE
    module Cap
      class ConfigureNetworks
        extend Vagrant::Util::Retryable
        include Vagrant::Util

        def self.configure_networks(machine, networks)
          comm = machine.communicate

          network_scripts_dir = machine.guest.capability(:network_scripts_dir)

          commands   = []
          interfaces = machine.guest.capability(:network_interfaces)

          networks.each.with_index do |network, i|
            network[:device] = interfaces[network[:interface]]

            entry = TemplateRenderer.render("guests/suse/network_#{network[:type]}",
              options: network,
            )

            remote_path = "/tmp/vagrant-network-#{network[:device]}-#{Time.now.to_i}-#{i}"

            Tempfile.open("vagrant-suse-configure-networks") do |f|
              f.binmode
              f.write(entry)
              f.fsync
              f.close
              comm.upload(f.path, remote_path)
            end

            local_path = "#{network_scripts_dir}/ifcfg-#{network[:device]}"
            commands << <<-EOH.gsub(/^ {14}/, '')
              /sbin/ifdown '#{network[:device]}' || true
              mv '#{remote_path}' '#{local_path}'
              /sbin/ifup '#{network[:device]}'
            EOH
          end

          comm.sudo(commands.join("\n"))
        end
      end
    end
  end
end
