require "tempfile"

require_relative "../../../../lib/vagrant/util/template_renderer"

module VagrantPlugins
  module GuestDebian
    module Cap
      class ConfigureNetworks
        include Vagrant::Util
        extend Vagrant::Util::GuestInspection::Linux

        def self.generate_netplan_cfg(options)
          cfg = {"network" => {"version" => 2,
                              "renderer" => "networkd",
                              "ethernets" => {}}}

          options.each do |option|
            cfg["network"]["ethernets"].merge!(option)
          end
          return cfg
        end

        def self.build_interface_entries(interface)
          entry = {interface[:device] => {"dhcp4" => true}}
          if interface[:ip]
            # is this always the right prefix length to pick??
            entry[interface[:device]].merge!({"addresses" => ["#{interface[:ip]}/24"]})
            entry[interface[:device]]["dhcp4"] = false
          end

          if interface[:gateway]
            entry[interface[:device]].merge!({"gateway4" => interface[:gateway]})
          end
          return entry
        end

        def self.determine_systemd_networkd(comm)
          return systemd?(comm) && systemd_networkd?(comm)
        end

        def self.upload_tmp_file(comm, content, remote_path)
          Tempfile.open("vagrant-debian-configure-networks") do |f|
            f.binmode
            f.write(content)
            f.fsync
            f.close
            comm.upload(f.path, remote_path)
          end
        end

        def self.configure_netplan_networks(machine, interfaces, comm, networks)
          commands = []
          entries = []

          root_device = interfaces.first
          networks.each do |network|
            network[:device] = interfaces[network[:interface]]

            options = network.merge(:root_device => root_device)
            entry = build_interface_entries(options)
            entries << entry
          end

          remote_path = "/tmp/vagrant-network-entry"

          netplan_cfg = generate_netplan_cfg(entries)
          content = netplan_cfg.to_yaml
          upload_tmp_file(comm, content, remote_path)

          commands << <<-EOH.gsub(/^ {12}/, "")
          mv '#{remote_path}' /etc/netplan/99-vagrant.yaml
          sudo netplan apply
          EOH

          return commands
        end

        def self.configure_networkd_networks(machine, interfaces, comm, networks)
          commands = []
          entries = []

          root_device = interfaces.first
          networks.each.with_index do |network,i|
            network[:device] = interfaces[network[:interface]]
            # generic systemd-networkd config file
            # update for debian
            entry = TemplateRenderer.render("guests/debian/networkd/network_#{network[:type]}",
              options: network,
            )

            remote_path = "/tmp/vagrant-network-#{network[:device]}-#{Time.now.to_i}-#{i}"
            upload_tmp_file(comm, entry, remote_path)

            commands << <<-EOH.gsub(/^ {14}/, '').rstrip
              # Configure #{network[:device]}
              mv '#{remote_path}' '/etc/systemd/network/#{network[:device]}.network' &&
              sudo chown root:root '/etc/systemd/network/#{network[:device]}.network' &&
              sudo chmod 644 '/etc/systemd/network/#{network[:device]}.network' &&
              ip link set '#{network[:device]}' down &&
              sudo rm /etc/resolv.conf &&
              sudo ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf &&
              sudo systemctl enable systemd-resolved.service &&
              sudo systemctl start systemd-resolved.service &&
              sudo systemctl enable systemd-networkd.service
              sudo systemctl start systemd-networkd.service
            EOH
          end

          return commands
        end

        def self.configure_other_networks(machine, interfaces, comm, networks)
          commands = []
          entries = []
          root_device = interfaces.first
          networks.each do |network|
            network[:device] = interfaces[network[:interface]]

            entry = TemplateRenderer.render("guests/debian/network_#{network[:type]}",
              options: network.merge(:root_device => root_device),
            )
            entries << entry
          end

          remote_path = "/tmp/vagrant-network-entry"
          content = entries.join("\n")
          upload_tmp_file(comm, content, remote_path)

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

          return commands
        end

        def self.configure_networks(machine, networks)
          comm = machine.communicate

          commands = []
          interfaces = machine.guest.capability(:network_interfaces)

          systemd_controlled = determine_systemd_networkd(comm)
          netplan_cli = netplan?(comm)

          if systemd_controlled
            if netplan_cli
              commands = configure_netplan_networks(machine, interfaces, comm, networks)
            else
              commands = configure_networkd_networks(machine, interfaces, comm, networks)
            end
          else
            commands = configure_other_networks(machine, interfaces, comm, networks)
          end

          # Run all the commands in one session to prevent partial configuration
          # due to a severed network.
          comm.sudo(commands.join("\n"))
        end
      end
    end
  end
end
