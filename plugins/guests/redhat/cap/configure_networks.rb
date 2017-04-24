require "tempfile"

require_relative "../../../../lib/vagrant/util/template_renderer"

module VagrantPlugins
  module GuestRedHat
    module Cap
      class ConfigureNetworks
        include Vagrant::Util
        extend Vagrant::Util::GuestInspection::Linux

        def self.configure_networks(machine, networks)
          comm = machine.communicate

          network_scripts_dir = machine.guest.capability(:network_scripts_dir)

          commands   = []
          interfaces = machine.guest.capability(:network_interfaces)

          # Check if NetworkManager is installed on the system
          nmcli_installed = nmcli?(comm)
          networks.each.with_index do |network, i|
            network[:device] = interfaces[network[:interface]]
            extra_opts = machine.config.vm.networks[i].last.dup

            if nmcli_installed
              # Now check if the device is actively being managed by NetworkManager
              nm_controlled = nm_controlled?(comm, network[:device])
            end

            if !extra_opts.key?(:nm_controlled)
              extra_opts[:nm_controlled] = !!nm_controlled
            end

            extra_opts[:nm_controlled] = case extra_opts[:nm_controlled]
                                      when true
                                        "yes"
                                      when false, nil
                                        "no"
                                      else
                                        extra_opts[:nm_controlled].to_s
                                      end

            if extra_opts[:nm_controlled] == "yes" && !nmcli_installed
              raise Vagrant::Errors::NetworkManagerNotInstalled, device: network[:device]
            end

            # Render a new configuration
            entry = TemplateRenderer.render("guests/redhat/network_#{network[:type]}",
              options: network.merge(extra_opts),
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

            if nm_controlled
              commands << "nmcli d disconnect '#{network[:device]}'"
            else
              commands << "/sbin/ifdown '#{network[:device]}'"
            end
            commands << "mv -f '#{remote_path}' '#{final_path}'"
            if nmcli_installed
              commands << "nmcli c reload"
            end
            if extra_opts[:nm_controlled] == "no"
              commands << "/sbin/ifup '#{network[:device]}'"
            else
              commands << "nmcli c up ifname '#{network[:device]}'"
            end
          end
          comm.sudo(commands.join("\n"))
        end
      end
    end
  end
end
