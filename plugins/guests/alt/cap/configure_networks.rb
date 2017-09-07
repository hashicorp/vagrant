require "tempfile"

require_relative "../../../../lib/vagrant/util/template_renderer"

module VagrantPlugins
  module GuestALT
    module Cap
      class ConfigureNetworks
        include Vagrant::Util
        extend Vagrant::Util::GuestInspection::Linux

        def self.configure_networks(machine, networks)
          comm = machine.communicate

          network_scripts_dir = machine.guest.capability(:network_scripts_dir)

          commands   = {:start => [], :middle => [], :end => []}
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
            template_options = network.merge(extra_opts)

            # ALT expects netmasks to be in the CIDR notation, but users may
            # specify IPV4 netmasks like "255.255.255.0". This magic converts
            # the netmask to the proper value.
            if template_options[:netmask] && template_options[:netmask].to_s.include?(".")
              template_options[:netmask] = (32-Math.log2((IPAddr.new(template_options[:netmask], Socket::AF_INET).to_i^0xffffffff)+1)).to_i
            end

            options_entry = TemplateRenderer.render("guests/alt/network_#{network[:type]}", options: template_options)

            # Upload the new configuration
            options_remote_path = "/tmp/vagrant-network-entry-#{network[:device]}-#{Time.now.to_i}-#{i}"
            ipv4_address_remote_path = "/tmp/vagrant-network-ipv4-address-entry-#{network[:device]}-#{Time.now.to_i}-#{i}"
            ipv4_route_remote_path = "/tmp/vagrant-network-ipv4-route-entry-#{network[:device]}-#{Time.now.to_i}-#{i}"

            Tempfile.open("vagrant-alt-configure-networks") do |f|
              f.binmode
              f.write(options_entry)
              f.fsync
              f.close
              machine.communicate.upload(f.path, options_remote_path)
            end

            # Add the new interface and bring it back up
            iface_path = "#{network_scripts_dir}/ifaces/#{network[:device]}"

            if network[:type].to_sym == :static
              ipv4_address_entry = TemplateRenderer.render("guests/alt/network_ipv4address", options: template_options)

              # Upload the new ipv4address configuration
              Tempfile.open("vagrant-alt-configure-ipv4-address") do |f|
                f.binmode
                f.write(ipv4_address_entry)
                f.fsync
                f.close
                machine.communicate.upload(f.path, ipv4_address_remote_path)
              end

              ipv4_route_entry = TemplateRenderer.render("guests/alt/network_ipv4route", options: template_options)

              # Upload the new ipv4route configuration
              Tempfile.open("vagrant-alt-configure-ipv4-route") do |f|
                f.binmode
                f.write(ipv4_route_entry)
                f.fsync
                f.close
                machine.communicate.upload(f.path, ipv4_route_remote_path)
              end
            end

            if nm_controlled and extra_opts[:nm_controlled] == "yes"
              commands[:start] << "nmcli d disconnect iface '#{network[:device]}'"
            else
              commands[:start] << "/sbin/ifdown '#{network[:device]}'"
            end
            commands[:middle] << "mkdir -p '#{iface_path}'"
            commands[:middle] << "mv -f '#{options_remote_path}' '#{iface_path}/options'"
            if network[:type].to_sym == :static
              commands[:middle] << "mv -f '#{ipv4_address_remote_path}' '#{iface_path}/ipv4address'"
              commands[:middle] << "mv -f '#{ipv4_route_remote_path}' '#{iface_path}/ipv4route'"
            end
            if extra_opts[:nm_controlled] == "no"
              commands[:end] << "/sbin/ifup '#{network[:device]}'"
            end
          end
          if nmcli_installed
            commands[:middle] << "((systemctl | grep NetworkManager.service) && systemctl restart NetworkManager) || " \
              "(test -f /etc/init.d/NetworkManager && /etc/init.d/NetworkManager restart)"
          end
          commands = commands[:start] + commands[:middle] + commands[:end]
          comm.sudo(commands.join("\n"))
          comm.wait_for_ready(5)
        end
      end
    end
  end
end
