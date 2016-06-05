require "tempfile"

require_relative "../../../../lib/vagrant/util/retryable"
require_relative "../../../../lib/vagrant/util/template_renderer"

module VagrantPlugins
  module GuestRedHat
    module Cap
      class ConfigureNetworks
        extend Vagrant::Util::Retryable
        include Vagrant::Util

        def self.configure_networks(machine, networks)
          case machine.guest.capability(:flavor)
          when :rhel_7
            configure_networks_rhel7(machine, networks)
          else
            configure_networks_default(machine, networks)
          end
        end

        def self.configure_networks_rhel7(machine, networks)
          # This is kind of jank but the configure networks is the same as
          # Fedora at this point.
          require_relative "../../fedora/cap/configure_networks"
          ::VagrantPlugins::GuestFedora::Cap::ConfigureNetworks
            .configure_networks(machine, networks)
        end

        def self.configure_networks_default(machine, networks)
          comm = machine.communicate

          network_scripts_dir = machine.guest.capability(:network_scripts_dir)

          interfaces = []
          commands   = []

          comm.sudo("ifconfig -a | grep -o ^[0-9a-z]* | grep -v '^lo'") do |_, stdout|
            interfaces = stdout.split("\n")
          end

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
            commands << <<-EOH.gsub(/^ {14}/, '')
              # Down the interface before munging the config file. This might
              # fail if the interface is not actually set up yet so ignore
              # errors.
              /sbin/ifdown '#{network[:device]}' || true

              # Move new config into place
              mv '#{remote_path}' '#{final_path}'

              # Bring the interface up
              ARPCHECK=no /sbin/ifup '#{network[:device]}'
            EOH
          end

          comm.sudo(commands.join("\n"))
        end
      end
    end
  end
end
