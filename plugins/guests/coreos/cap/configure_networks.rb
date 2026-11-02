# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require "tempfile"
require "yaml"

require_relative "../../../../lib/vagrant/util/template_renderer"

module VagrantPlugins
  module GuestCoreOS
    module Cap
      class ConfigureNetworks
        extend Vagrant::Util::GuestInspection::Linux

        NETWORK_MANAGER_CONN_DIR = "/etc/NetworkManager/system-connections".freeze
        DEFAULT_ENVIRONMENT_IP = "127.0.0.1".freeze

        def self.configure_networks(machine, networks)
          comm = machine.communicate
          return configure_networks_cloud_init(machine, networks) if comm.test("command -v cloud-init")

          interfaces = machine.guest.capability(:network_interfaces)
          nm_dev = {}
          comm.execute("nmcli -t c show") do |type, data|
            if type == :stdout
              _, id, _, dev = data.strip.split(":")
              nm_dev[dev] = id
            end
          end
          comm.sudo("rm #{File.join(NETWORK_MANAGER_CONN_DIR, 'vagrant-*.conf')}",
            error_check: false)

          networks.each_with_index do |network, i|
            network[:device] = interfaces[network[:interface]]
            addr = IPAddr.new(network[:ip])
            mask = addr.mask(network[:netmask])
            if !network[:mac_address]
              comm.execute("cat /sys/class/net/#{network[:device]}/address") do |type, data|
                if type == :stdout
                  network[:mac_address] = data
                end
              end
            end

            f = Tempfile.new("vagrant-coreos-network")
            {
              connection: {
                type: "ethernet",
                id: network[:device],
                "interface-name": network[:device]
              },
              ethernet: {
                "mac-address": network[:mac_address]
              },
              ipv4: {
                method: "manual",
                addresses: "#{network[:ip]}/#{mask.prefix}",
                gateway: network.fetch(:gateway, mask.to_range.first.succ),
              },
            }.each_pair do |section, content|
              f.puts "[#{section}]"
              content.each_pair do |key, value|
                f.puts "#{key}=#{value}"
              end
            end
            f.close
            comm.sudo("nmcli d disconnect '#{network[:device]}'", error_check: false)
            comm.sudo("nmcli c delete '#{nm_dev[network[:device]]}'", error_check: false)
            dst = File.join("/var/tmp", "vagrant-#{network[:device]}.conf")
            final = File.join(NETWORK_MANAGER_CONN_DIR, "vagrant-#{network[:device]}.conf")
            comm.upload(f.path, dst)
            comm.sudo("chown root:root '#{dst}'")
            comm.sudo("chmod 0600 '#{dst}'")
            comm.sudo("mv '#{dst}' '#{final}'")
            comm.sudo("nmcli c load '#{final}'")
            comm.sudo("nmcli d connect '#{network[:device]}'")
            f.delete
          end
        end

        def self.configure_networks_cloud_init(machine, networks)
          cloud_config = {}
          # Locate configured IP addresses to drop in /etc/environment
          # for export. If no addresses found, fall back to default
          public_ip = catch(:public_ip) do
            machine.config.vm.networks.each do |type, opts|
              next if type != :public_network
              throw(:public_ip, opts[:ip]) if opts[:ip]
            end
            DEFAULT_ENVIRONMENT_IP
          end
          private_ip = catch(:private_ip) do
            machine.config.vm.networks.each do |type, opts|
              next if type != :private_network
              throw(:private_ip, opts[:ip]) if opts[:ip]
            end
            public_ip
          end
          cloud_config["write_files"] = [
            {"path" => "/etc/environment",
              "content" => "COREOS_PUBLIC_IPV4=#{public_ip}\nCOREOS_PRIVATE_IPV4=#{private_ip}"}
          ]

          # Generate configuration for any static network interfaces
          # which have been defined
          interfaces = machine.guest.capability(:network_interfaces)
          units = networks.map do |network|
            iface = network[:interface].to_i
            unit_name = "50-vagrant#{iface}.network"
            device = interfaces[iface]
            if network[:type].to_s == "dhcp"
              network_content = "DHCP=yes"
            else
              prefix = IPAddr.new("255.255.255.255/#{network[:netmask]}").to_i.to_s(2).count("1")
              address = "#{network[:ip]}/#{prefix}"
              network_content = "Address=#{address}"
            end
            {"name" => unit_name,
              "runtime" => "no",
              "content" => "[Match]\nName=#{device}\n[Network]\n#{network_content}"}
          end
          cloud_config["coreos"] = {"units" => units.compact}

          # Upload configuration and apply
          file = Tempfile.new("vagrant-coreos-networks")
          file.puts("#cloud-config\n")
          file.puts(cloud_config.to_yaml)
          file.close

          dst = "/var/tmp/networks.yml"
          svc_path = dst.tr("/", "-")[1..-1]
          machine.communicate.upload(file.path, dst)
          machine.communicate.sudo("systemctl start system-cloudinit@#{svc_path}.service")
        end
      end
    end
  end
end
