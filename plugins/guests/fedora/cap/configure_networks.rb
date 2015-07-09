require "set"
require "tempfile"

require "vagrant/util/retryable"
require "vagrant/util/template_renderer"

module VagrantPlugins
  module GuestFedora
    module Cap
      class ConfigureNetworks
        extend Vagrant::Util::Retryable
        include Vagrant::Util

        def self.configure_networks(machine, networks)
          network_scripts_dir = machine.guest.capability("network_scripts_dir")

          virtual = false
          interface_names = Array.new
          machine.communicate.sudo("/usr/sbin/biosdevname; echo $?") do |_, result|
            virtual = true if ['4', '127'].include? result.chomp
          end

          if virtual
            machine.communicate.sudo("ls /sys/class/net | egrep -v lo\\|docker") do |_, result|
              interface_names = result.split("\n")
            end

            interface_names = networks.map do |network|
               "#{interface_names[network[:interface]]}"
            end
          else
            machine.communicate.sudo("/usr/sbin/biosdevname -d | grep Kernel | cut -f2 -d: | sed -e 's/ //;'") do |_, result|
              interface_names = result.split("\n")
            end

            interface_name_pairs = Array.new
            interface_names.each do |interface_name|
              machine.communicate.sudo("/usr/sbin/biosdevname --policy=all_ethN -i #{interface_name}") do |_, result|
                interface_name_pairs.push([interface_name, result.gsub("\n", "")])
              end
            end

            setting_interface_names = networks.map do |network|
               "eth#{network[:interface]}"
            end

            interface_name_pairs.each do |interface_name, previous_interface_name|
              if setting_interface_names.index(previous_interface_name) == nil
                interface_names.delete(interface_name)
              end
            end
          end

          # Accumulate the configurations to add to the interfaces file as well
          # as what interfaces we're actually configuring since we use that later.
          interfaces = Set.new
          networks.each do |network|
            interface = interface_names[network[:interface]-1]
            interfaces.add(interface)
            network[:device] = interface

            # Remove any previous vagrant configuration in this network
            # interface's configuration files.
            machine.communicate.sudo("touch #{network_scripts_dir}/ifcfg-#{interface}")
            machine.communicate.sudo("sed -e '/^#VAGRANT-BEGIN/,/^#VAGRANT-END/ d' #{network_scripts_dir}/ifcfg-#{interface} > /tmp/vagrant-ifcfg-#{interface}")
            machine.communicate.sudo("cat /tmp/vagrant-ifcfg-#{interface} > #{network_scripts_dir}/ifcfg-#{interface}")
            machine.communicate.sudo("rm -f /tmp/vagrant-ifcfg-#{interface}")

            # Render and upload the network entry file to a deterministic
            # temporary location.
            entry = TemplateRenderer.render("guests/fedora/network_#{network[:type]}",
                                            options: network)

            temp = Tempfile.new("vagrant")
            temp.binmode
            temp.write(entry)
            temp.close

            machine.communicate.upload(temp.path, "/tmp/vagrant-network-entry_#{interface}")
          end

          # Bring down all the interfaces we're reconfiguring. By bringing down
          # each specifically, we avoid reconfiguring p7p (the NAT interface) so
          # SSH never dies.
          interfaces.each do |interface|
            retryable(on: Vagrant::Errors::VagrantError, tries: 3, sleep: 2) do
              machine.communicate.sudo("cat /tmp/vagrant-network-entry_#{interface} >> #{network_scripts_dir}/ifcfg-#{interface}")
              machine.communicate.sudo("which nmcli >/dev/null 2>&1 && nmcli c reload #{interface}")
              machine.communicate.sudo("/sbin/ifdown #{interface}", error_check: true)
              machine.communicate.sudo("/sbin/ifup #{interface}")
            end

            machine.communicate.sudo("rm -f /tmp/vagrant-network-entry_#{interface}")
          end
        end
      end
    end
  end
end
