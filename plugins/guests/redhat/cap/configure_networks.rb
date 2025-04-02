# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require "tempfile"
require "securerandom"

require_relative "../../../../lib/vagrant/util/template_renderer"

module VagrantPlugins
  module GuestRedHat
    module Cap
      class ConfigureNetworks
        include Vagrant::Util
        extend Vagrant::Util::GuestInspection::Linux

        def self.configure_networks(machine, networks)
          @logger = Log4r::Logger.new("vagrant::guest::redhat::configurenetworks")

          # Start with the scripts directory to determine how to configure
          network_scripts_dir = machine.guest.capability(:network_scripts_dir)
          @logger.debug("guest network scripts directory: #{network_scripts_dir}")

          # The legacy configuration will handle rhel/centos pre-10
          # versions. The newer versions have a different path for
          # network configuration files.

          return configure_networks_legacy(machine, networks) if network_scripts_dir.end_with?("network-scripts")

          comm = machine.communicate

          interfaces = machine.guest.capability(:network_interfaces)
          net_configs = machine.config.vm.networks.find_all { |type, _| type.to_s.end_with?("_network") }.map(&:last)

          # Get IDs of currently configured devices
          current_devs = Hash.new.tap do |cd|
            comm.execute("nmcli -t c show") do |type, data|
              if type == :stdout
                _, id, _, dev = data.strip.split(":")
                cd[dev] = id
              end
            end
          end

          networks.each.with_index do |network, i|
            net_opts = (net_configs[i] || {}).merge(network)
            net_opts[:type] = net_opts[:type].to_s
            net_opts[:device] = interfaces[network[:interface]]

            if !net_opts[:mac_address]
              comm.execute("cat /sys/class/net/#{net_opts[:device]}/address") do |type, data|
                net_opts[:mac_address] = data if type == :stdout
              end
            end

            tmpl_opts = {
              interface_name: net_opts[:device],
              type: net_opts[:type],
              mac_address: net_opts[:mac_address],
              uuid: SecureRandom.uuid
            }

            if net_opts[:type] != "dhcp"
              begin
                addr = IPAddr.new("#{net_opts[:ip]}")
                if addr.ipv4?
                  tmpl_opts[:ipv4] = addr.to_string
                  masked = addr.mask(net_opts[:netmask])

                  tmpl_opts[:ipv4_mask] = masked.prefix
                  tmpl_opts[:ipv4_gateway] = masked.succ.to_string
                else
                  tmpl_opts[:ipv6] = addr.to_string
                  masked = addr.mask(net_opts[:netmask])

                  tmpl_opts[:ipv6_mask] = masked.prefix
                  tmpl_opts[:ipv6_gateway] = masked.succ.to_string
                end
              rescue IPAddr::Error => err
                raise NetworkAddressInvalid,
                  address: net_opts[:ip],
                  mask: net_opts[:netmask],
                  error: err.to_s
              end
            end

            entry = TemplateRenderer.render("guests/redhat/network_manager_device", options: tmpl_opts)
            remote_path = "/tmp/vagrant-network-entry-#{net_opts[:device]}-#{Time.now.to_i}-#{i}"
            final_path = "#{network_scripts_dir}/#{net_opts[:device]}.nmconnection"

            Tempfile.open("vagrant-redhat-configure-networks") do |f|
              f.binmode
              f.write(entry)
              f.fsync
              f.close
              comm.upload(f.path, remote_path)
            end

            # Remove the device if it already exists
            if device_id = current_devs[net_opts[:device]]
              [
                "nmcli d disconnect '#{net_opts[:device]}'",
                "nmcli c delete '#{device_id}'",
              ].each do |cmd|
                comm.sudo(cmd, error_check: false)
              end
            end

            # Apply the config
            [
              "chown root:root '#{remote_path}'",
              "chmod 0600 '#{remote_path}'",
              "mv '#{remote_path}' '#{final_path}'",
              "nmcli c load '#{final_path}'",
              "nmcli d connect '#{net_opts[:device]}'"
            ].each do |cmd|
              comm.sudo(cmd)
            end
          end
        end

        def self.configure_networks_legacy(machine, networks)
          comm = machine.communicate

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
