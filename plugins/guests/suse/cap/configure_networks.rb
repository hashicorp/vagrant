require "set"
require "tempfile"

require "vagrant/util/retryable"
require "vagrant/util/template_renderer"

module VagrantPlugins
  module GuestSuse
    module Cap
      class ConfigureNetworks
        extend Vagrant::Util::Retryable
        include Vagrant::Util

        def self.configure_networks(machine, networks)
          network_scripts_dir = machine.guest.capability("network_scripts_dir")

          # Accumulate the configurations to add to the interfaces file as
          # well as what interfaces we're actually configuring since we use that
          # later.
          interfaces = Set.new
          networks.each do |network|
            interfaces.add(network[:interface])

            # Remove any previous vagrant configuration in this network interface's
            # configuration files.
            machine.communicate.sudo("touch #{network_scripts_dir}/ifcfg-eth#{network[:interface]}")
            machine.communicate.sudo("sed -e '/^#VAGRANT-BEGIN/,/^#VAGRANT-END/ d' #{network_scripts_dir}/ifcfg-eth#{network[:interface]} > /tmp/vagrant-ifcfg-eth#{network[:interface]}")
            machine.communicate.sudo("cat /tmp/vagrant-ifcfg-eth#{network[:interface]} > #{network_scripts_dir}/ifcfg-eth#{network[:interface]}")
            machine.communicate.sudo("rm /tmp/vagrant-ifcfg-eth#{network[:interface]}")

            # Render and upload the network entry file to a deterministic
            # temporary location.
            entry = TemplateRenderer.render("guests/suse/network_#{network[:type]}",
                                            :options => network)

            temp = Tempfile.new("vagrant")
            temp.binmode
            temp.write(entry)
            temp.close

            machine.communicate.upload(temp.path, "/tmp/vagrant-network-entry_#{network[:interface]}")
          end

          # Bring down all the interfaces we're reconfiguring. By bringing down
          # each specifically, we avoid reconfiguring eth0 (the NAT interface) so
          # SSH never dies.
          interfaces.each do |interface|
            retryable(:on => Vagrant::Errors::VagrantError, :tries => 3, :sleep => 2) do
              machine.communicate.sudo("/sbin/ifdown eth#{interface} 2> /dev/null", :error_check => false)
              machine.communicate.sudo("cat /tmp/vagrant-network-entry_#{interface} >> #{network_scripts_dir}/ifcfg-eth#{interface}")
              machine.communicate.sudo("/sbin/ifup eth#{interface} 2> /dev/null")
            end

            machine.communicate.sudo("rm /tmp/vagrant-network-entry_#{interface}")
          end
        end
      end
    end
  end
end
