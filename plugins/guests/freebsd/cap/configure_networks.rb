require_relative "../../../../lib/vagrant/util/template_renderer"
require_relative "../../../../lib/vagrant/util/tempfile"

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

            Tempfile.create("freebsd-configure-networks") do |f|
              f.write(entry)
              f.fsync
              f.close
              machine.communicate.upload(f.path, "/tmp/vagrant-network-entry")
            end

            machine.communicate.sudo("su -m root -c 'cat /tmp/vagrant-network-entry >> /etc/rc.conf'", {shell: "sh"})
            machine.communicate.sudo("rm -f /tmp/vagrant-network-entry", {shell: "sh"})

            # Restart interface so it loads configuration stored in /etc/rc.conf
            machine.communicate.sudo("service netif restart #{ifname}", {shell: "sh"})
          end
        end
      end
    end
  end
end
