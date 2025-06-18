# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

module Vagrant
  module Util
    # Helper methods for configuring guest networks
    module GuestNetworks
      module Linux
        NETWORK_MANAGER_DEVICE_DIRECTORY = "/etc/NetworkManager/system-connections".freeze

        def configure_network_manager(machine, networks, **opts)
          comm = machine.communicate
          nm_directory = opts.fetch(:nm_directory, NETWORK_MANAGER_DEVICE_DIRECTORY)

          interfaces = machine.guest.capability(:network_interfaces)
          net_configs = machine.config.vm.networks.find_all { |type, _| type.to_s.end_with?("_network") }.map(&:last)

          # Get IDs of currently configured devices
          current_devs = get_current_devices(comm)

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

            entry = TemplateRenderer.render("networking/network_manager/network_manager_device", options: tmpl_opts)
            remote_path = "/tmp/vagrant-network-entry-#{net_opts[:device]}-#{Time.now.to_i}-#{i}"
            final_path = "#{nm_directory}/#{net_opts[:device]}.nmconnection"

            Tempfile.open("vagrant-nm-configure-networks") do |f|
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

        # Get all network devices currently managed by NetworkManager.
        # @param [Vagrant::Plugin::V2::Communicator] comm Guest communicator
        # @return [Hash] A hash of current device names and their associated IDs.
        def get_current_devices(comm)
          {}.tap do |cd|
            comm.execute("nmcli -t c show") do |type, data|
              if type == :stdout
                data.strip.lines.map(&:chomp).each do |line|
                  next if line.strip.empty?
                  _, id, _, dev = line.strip.split(':')
                  cd[dev] = id
                end
              end
            end
          end
        end
      end
    end
  end
end
