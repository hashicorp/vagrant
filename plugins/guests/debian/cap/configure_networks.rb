require 'set'
require 'tempfile'

require "vagrant/util/template_renderer"

module VagrantPlugins
  module GuestDebian
    module Cap
      class ConfigureNetworks
        include Vagrant::Util

        def self.configure_networks(machine, networks)
          machine.communicate.tap do |comm|
            # First, remove any previous network modifications
            # from the interface file.

            # Grab all of the lines before the first instance of #VAGRANT-BEGIN
            # and write to the pre file
            comm.sudo("sed -e '/^#VAGRANT-BEGIN/,$ d' /etc/network/interfaces > /tmp/vagrant-network-interfaces.pre")

            # Find the last instance of #VAGRANT-END and print all of the lines
            # after it to the post file
            comm.sudo("tail -n +$(expr $(grep -n \"#VAGRANT-END\" /etc/network/interfaces | tail -n 1 | sed -rn 's/^([[:digit:]]+):.*$/\\1/p') + 1) /etc/network/interfaces > /tmp/vagrant-network-interfaces.post")

            # Accumulate the configurations to add to the interfaces file as
            # well as what interfaces we're actually configuring since we use that
            # later.
            interfaces = Set.new
            entries = []
            networks.each do |network|
              interfaces.add(network[:interface])
              entry = TemplateRenderer.render("guests/debian/network_#{network[:type]}",
                                              options: network)

              entries << entry
            end

            # If we generated any interface definitions, surround them with
            # VAGRANT-BEGIN and VAGRANT-END so we can find them later.
            unless entries.empty?
              entries.unshift("#VAGRANT-BEGIN")
              entries << "#VAGRANT-END\n"
            end

            # Perform the careful dance necessary to reconfigure
            # the network interfaces
            temp = Tempfile.new("vagrant")
            temp.binmode
            temp.write(entries.join("\n"))
            temp.close

            comm.upload(temp.path, "/tmp/vagrant-network-entry")

            # Bring down all the interfaces we're reconfiguring. By bringing down
            # each specifically, we avoid reconfiguring eth0 (the NAT interface) so
            # SSH never dies.
            interfaces.each do |interface|
              comm.sudo("/sbin/ifdown eth#{interface} 2> /dev/null")
              comm.sudo("/sbin/ip addr flush dev eth#{interface} 2> /dev/null")
            end

            comm.sudo('cat /tmp/vagrant-network-interfaces.pre /tmp/vagrant-network-entry /tmp/vagrant-network-interfaces.post > /etc/network/interfaces')
            comm.sudo('rm -f /tmp/vagrant-network-interfaces.pre /tmp/vagrant-network-entry /tmp/vagrant-network-interfaces.post')

            # Bring back up each network interface, reconfigured
            interfaces.each do |interface|
              comm.sudo("/sbin/ifup eth#{interface}")
            end
          end
        end
      end
    end
  end
end
