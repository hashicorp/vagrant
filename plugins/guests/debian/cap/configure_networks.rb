require "tempfile"

require_relative "../../../../lib/vagrant/util/template_renderer"

module VagrantPlugins
  module GuestDebian
    module Cap
      class ConfigureNetworks
        include Vagrant::Util
        extend Vagrant::Util::GuestInspection::Linux

        NETPLAN_DEFAULT_VERSION = 2
        NETPLAN_DEFAULT_RENDERER = "networkd".freeze
        NETPLAN_DIRECTORY = "/etc/netplan".freeze
        NETWORKD_DIRECTORY = "/etc/systemd/network".freeze


        def self.configure_networks(machine, networks)
          comm = machine.communicate
          interfaces = machine.guest.capability(:network_interfaces)

          if netplan?(comm)
            configure_netplan(machine, interfaces, comm, networks)
          elsif systemd?(comm)
            if systemd_networkd?(comm)
              configure_networkd(machine, interfaces, comm, networks)
            else
              configure_systemd(machine, interfaces, comm, networks)
            end
          else
            configure_nettools(machine, interfaces, comm, networks)
          end
        end

        # Configure networking using netplan
        def self.configure_netplan(machine, interfaces, comm, networks)
          ethernets = {}.tap do |e_nets|
            networks.each do |network|
              e_config = {}.tap do |entry|
                if network[:ip]
                  mask = IPAddr.new(network.fetch(:netmask, "255.255.255.0")).to_i.to_s(2).count("1")
                  entry["addresses"] = ["#{network[:ip]}/#{mask}"]
                else
                  entry["dhcp4"] = true
                end
                if network[:gateway]
                  entry["gateway4"] = network[:gateway]
                end
              end
              e_nets[interfaces[network[:interface]]] = e_config
            end
          end
          np_config = {"network" => {"version" => NETPLAN_DEFAULT_VERSION,
            "renderer" => NETPLAN_DEFAULT_RENDERER, "ethernets" => ethernets}}

          remote_path = upload_tmp_file(comm, np_config.to_yaml)
          dest_path = "#{NETPLAN_DIRECTORY}/99-vagrant.yaml"
          comm.sudo(["mv -f '#{remote_path}' '#{dest_path}'",
            "chown root:root '#{dest_path}'",
            "chmod 0644 '#{dest_path}'",
            "netplan apply"].join("\n"))
        end

        # Configure guest networking using networkd
        def self.configure_networkd(machine, interfaces, comm, networks)
          net_conf = []

          root_device = interfaces.first
          networks.each do |network|
            dev_name = interfaces[network[:interface]]
            net_conf << "[Match]"
            net_conf << "Name=#{dev_name}"
            net_conf << "[Network]"
            if network[:ip]
              mask = IPAddr.new(network.fetch(:netmask, "255.255.255.0")).to_i.to_s(2).count("1")
              net_conf << "DHCP=no"
              net_conf << "Address=#{network[:ip]}/#{mask}"
              net_conf << "Gateway=#{network[:gateway]}" if network[:gateway]
            else
              net_conf << "DHCP=yes"
            end
          end

          remote_path = upload_tmp_file(comm, net_conf.join("\n"))
          dest_path = "#{NETWORKD_DIRECTORY}/99-vagrant.network"
          comm.sudo(["mkdir -p #{NETWORKD_DIRECTORY}",
            "mv -f '#{remote_path}' '#{dest_path}'",
            "chown root:root '#{dest_path}'",
            "chmod 0644 '#{dest_path}'",
            "systemctl restart systemd-networkd.service"].join("\n"))
        end

        # Configure guest networking using net-tools
        def self.configure_nettools(machine, interfaces, comm, networks)
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

          content = entries.join("\n")
          remote_path = "/tmp/vagrant-network-entry"
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
          comm.sudo(commands.join("\n"))
        end

        # Simple helper to upload content to guest temporary file
        #
        # @param [Vagrant::Plugin::Communicator] comm
        # @param [String] content
        # @return [String] remote path
        def self.upload_tmp_file(comm, content, remote_path=nil)
          if remote_path.nil?
            remote_path = "/tmp/vagrant-network-entry-#{Time.now.to_i}"
          end
          Tempfile.open("vagrant-debian-configure-networks") do |f|
            f.binmode
            f.write(content)
            f.fsync
            f.close
            comm.upload(f.path, remote_path)
          end
          remote_path
        end
      end
    end
  end
end
