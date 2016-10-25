require "tempfile"

require_relative "../../../../lib/vagrant/util/template_renderer"

module VagrantPlugins
  module GuestRedHat
    module Cap
      class ConfigureNetworks
        include Vagrant::Util

        def self.configure_networks(machine, networks)
          comm = machine.communicate

          network_scripts_dir = machine.guest.capability(:network_scripts_dir)

          commands   = []
          interfaces = machine.guest.capability(:network_interfaces)

          networks.each.with_index do |network, i|
            network[:device] = interfaces[network[:interface]]

            # Render a new configuration
            entry = TemplateRenderer.render("guests/redhat/network_#{network[:type]}",
              options: network,
            )

            # Upload the new configuration
            remote_path = "/tmp/vagrant-network-entry-#{network[:device]}-#{Time.now.to_i}-#{i}"
            Tempfile.open("vagrant-redhat-configure-networks") do |f|
              f.binmode
              f.write(entry)
              f.fsync
              f.close
              machine.communicate.upload(f.path, remote_path)
            end

            # Add the new interface and bring it back up
            final_path = "#{network_scripts_dir}/ifcfg-#{network[:device]}"
            commands << <<-EOH.gsub(/^ */, '')
              # Down the interface before munging the config file. This might
              # fail if the interface is not actually set up yet so ignore
              # errors.
              /sbin/ifdown '#{network[:device]}'
              # Move new config into place
              mv -f '#{remote_path}' '#{final_path}'
              # attempt to force network manager to reload configurations
              nmcli c reload || true
            EOH
          end

          commands << <<-EOH.gsub(/^ */, '')
            # Restart network
            service network restart
          EOH

          comm.sudo(commands.join("\n"))
        end
      end
    end
  end
end
