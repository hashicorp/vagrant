require "set"
require "tempfile"

require "vagrant/util/retryable"
require "vagrant/util/template_renderer"

module VagrantPlugins
  module GuestRedHat
    module Cap
      class ConfigureNetworks
        extend Vagrant::Util::Retryable
        include Vagrant::Util

        def self.configure_networks(machine, networks)
          network_scripts_dir = machine.guest.capability("network_scripts_dir")
          interface_names = machine.guest.capability("interfaces_list")
      
          # Accumulate the configurations to add to the interfaces file as
          # well as what interfaces we're actually configuring since we use that
          # later.
          interfaces = Set.new
          networks.each do |network|
            interface = interface_names[network[:interface]]
            interfaces.add(interface)
            network[:device] = interface
            
            # Remove any previous vagrant configuration in this network interface's
            # configuration files.
            machine.communicate.sudo("touch #{network_scripts_dir}/ifcfg-#{interface}")
            machine.communicate.sudo("sed -e '/^#VAGRANT-BEGIN/,/^#VAGRANT-END/ d' #{network_scripts_dir}/ifcfg-#{interface} > /tmp/vagrant-ifcfg-#{interface}")
            machine.communicate.sudo("cat /tmp/vagrant-ifcfg-#{interface} > #{network_scripts_dir}/ifcfg-#{interface}")
            machine.communicate.sudo("rm /tmp/vagrant-ifcfg-#{interface}")
           
            # Render and upload the network entry file to a deterministic
            # temporary location.
            # use fedora for now
            entry = TemplateRenderer.render("guests/redhat/network_#{network[:type]}",
                                            :options => network)

            temp = Tempfile.new("vagrant")
            temp.binmode
            temp.write(entry)
            temp.close

            machine.communicate.upload(temp.path, "/tmp/vagrant-network-entry_#{interface}")
          end

          # Bring down all the interfaces we're reconfiguring. By bringing down
          # each specifically, we avoid reconfiguring eth0 (the NAT interface) so
          # SSH never dies.
          interfaces.each do |interface|
            retryable(:on => Vagrant::Errors::VagrantError, :tries => 3, :sleep => 2) do
              machine.communicate.sudo("cat /tmp/vagrant-network-entry_#{interface} >> #{network_scripts_dir}/ifcfg-#{interface}")
              machine.communicate.sudo("/sbin/ifdown #{interface}", :error_check => true)  
              machine.communicate.sudo("/sbin/ifup #{interface}")
            end
            machine.communicate.sudo("rm /tmp/vagrant-network-entry_#{interface}")
          end
        end
      end
    end
  end
end
