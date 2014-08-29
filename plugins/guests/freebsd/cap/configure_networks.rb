require "tempfile"

require "vagrant/util/template_renderer"

module VagrantPlugins
  module GuestFreeBSD
    module Cap
      class ConfigureNetworks
        include Vagrant::Util

        def self.configure_networks(machine, networks)
          # Remove any previous network additions to the configuration file.
          machine.communicate.sudo("sed -i '' -e '/^#VAGRANT-BEGIN/,/^#VAGRANT-END/ d' /etc/rc.conf", {shell: "sh"})

          networks.each do |network|
            # Determine the interface prefix...
            command = "ifconfig -a | grep -o ^[0-9a-z]*"
            result = ""
            ifname = ""
            machine.communicate.execute(command) do |type, data|
              result << data if type == :stdout
              if result.split(/\n/).any?{|i| i.match(/vtnet*/)}
                ifname = "vtnet#{network[:interface]}"
              else
                ifname = "em#{network[:interface]}"
              end
            end

            entry  = TemplateRenderer.render("guests/freebsd/network_#{network[:type]}",
                                            options: network, ifname: ifname)

            # Write the entry to a temporary location
            temp = Tempfile.new("vagrant")
            temp.binmode
            temp.write(entry)
            temp.close

            machine.communicate.upload(temp.path, "/tmp/vagrant-network-entry")
            machine.communicate.sudo("su -m root -c 'cat /tmp/vagrant-network-entry >> /etc/rc.conf'", {shell: "sh"})
            machine.communicate.sudo("rm -f /tmp/vagrant-network-entry", {shell: "sh"})

            if network[:type].to_sym == :static
              machine.communicate.sudo("ifconfig #{ifname} inet #{network[:ip]} netmask #{network[:netmask]}", {shell: "sh"})
            elsif network[:type].to_sym == :dhcp
              machine.communicate.sudo("dhclient #{ifname}", {shell: "sh"})
            end
          end
        end
      end
    end
  end
end
