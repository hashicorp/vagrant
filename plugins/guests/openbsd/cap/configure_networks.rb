require "tempfile"

require_relative "../../../../lib/vagrant/util/template_renderer"

module VagrantPlugins
  module GuestOpenBSD
    module Cap
      class ConfigureNetworks
        include Vagrant::Util

        def self.configure_networks(machine, networks)
          networks.each do |network|
            entry = TemplateRenderer.render("guests/openbsd/network_#{network[:type]}",
                                            options: network)

            Tempfile.open("vagrant-openbsd-configure-networks") do |f|
              f.binmode
              f.write(entry)
              f.fsync
              f.close
              machine.communicate.upload(f.path, "/tmp/vagrant-network-entry")
            end

            # Determine the interface prefix...
            command = "ifconfig -a | grep -o ^[0-9a-z]*"
            result = ""
            ifname = ""
            machine.communicate.execute(command) do |type, data|
              result << data if type == :stdout
              if result.split(/\n/).any?{|i| i.match(/vio*/)}
                ifname = "vio#{network[:interface]}"
              else
                ifname = "em#{network[:interface]}"
              end
            end

            machine.communicate.sudo("mv /tmp/vagrant-network-entry /etc/hostname.#{ifname}")

            # remove old configurations
            machine.communicate.sudo("sudo ifconfig #{ifname} inet delete", { error_check: false })
            machine.communicate.sudo("pkill -f 'dhclient: #{ifname}'", { error_check: false })

            if network[:type].to_sym == :static
              machine.communicate.sudo("ifconfig #{ifname} inet #{network[:ip]} netmask #{network[:netmask]}")
            elsif network[:type].to_sym == :dhcp
              machine.communicate.sudo("dhclient #{ifname}")
            end
          end
        end
      end
    end
  end
end
