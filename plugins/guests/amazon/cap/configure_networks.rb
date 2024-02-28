# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require "tempfile"

require_relative "../../../../lib/vagrant/util/template_renderer"

module VagrantPlugins
  module GuestAmazon
    module Cap
      class ConfigureNetworks
        include Vagrant::Util
        extend Vagrant::Util::GuestInspection::Linux

        NETWORKD_DIRECTORY = "/etc/systemd/network".freeze

        def self.configure_networks(machine, networks)
          comm = machine.communicate
          interfaces = machine.guest.capability(:network_interfaces)

          if systemd?(comm)
            if systemd_networkd?(comm)
              configure_networkd(machine, interfaces, comm, networks)
            else
              configure_network_scripts(machine, interfaces, comm, networks)
            end
          else
            configure_network_scripts(machine, interfaces, comm, networks)
          end
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

        # Configure guest networking using networkd
        def self.configure_networkd(machine, interfaces, comm, networks)
          root_device = interfaces.first
          networks.each do |network|
            dev_name = interfaces[network[:interface]]
            net_conf = []
            net_conf << "[Match]"
            net_conf << "Name=#{dev_name}"
            net_conf << "[Network]"
            if network[:type].to_s == "dhcp"
              net_conf << "DHCP=yes"
            else
              mask = network[:netmask]
              if mask && IPAddr.new(network[:ip]).ipv4?
                begin
                  mask = IPAddr.new(mask).to_i.to_s(2).count("1")
                rescue IPAddr::Error
                  # ignore and use given value
                end
              end
              address = [network[:ip], mask].compact.join("/")
              net_conf << "DHCP=no"
              net_conf << "Address=#{address}"
              net_conf << "Gateway=#{network[:gateway]}" if network[:gateway]
            end

            remote_path = upload_tmp_file(comm, net_conf.join("\n"))
            dest_path = "/etc/systemd/network/50-vagrant-#{dev_name}.network"
            comm.sudo(["mkdir -p /etc/systemd/network",
              "mv -f '#{remote_path}' '#{dest_path}'",
              "chown root:root '#{dest_path}'",
              "chmod 0644 '#{dest_path}'"].join("\n"))
          end

          comm.sudo(["systemctl restart systemd-networkd.service"].join("\n"))
        end

        def self.configure_network_scripts(machine, interfaces, comm, networks)
          network_scripts_dir = machine.guest.capability(:network_scripts_dir)

          commands   = {:start => [], :middle => [], :end => []}
          interfaces = machine.guest.capability(:network_interfaces)

          # Check if NetworkManager is installed on the system
          nmcli_installed = nmcli?(comm)
          net_configs = machine.config.vm.networks.map do |type, opts|
            opts if type.to_s.end_with?("_network")
          end.compact
          networks.each.with_index do |network, i|
            network[:device] = interfaces[network[:interface]]
            extra_opts = net_configs[i] ? net_configs[i].dup : {}

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
              options: extra_opts.merge(network),
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
              commands[:start] << "nmcli d disconnect iface '#{network[:device]}'"
            else
              commands[:start] << "/sbin/ifdown '#{network[:device]}'"
            end
            commands[:middle] << "mv -f '#{remote_path}' '#{final_path}'"
            if extra_opts[:nm_controlled] == "no"
              commands[:end] << "/sbin/ifup '#{network[:device]}'"
            end
          end
          if nmcli_installed
            commands[:middle] << "(test -f /etc/init.d/NetworkManager && /etc/init.d/NetworkManager restart) || " \
              "((systemctl | grep NetworkManager.service) && systemctl restart NetworkManager)"
          end
          commands = commands[:start] + commands[:middle] + commands[:end]
          comm.sudo(commands.join("\n"))
          comm.wait_for_ready(5)
        end
      end
    end
  end
end
