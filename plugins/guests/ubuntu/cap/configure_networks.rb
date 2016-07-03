module VagrantPlugins
  module GuestUbuntu
    module Cap
      class ConfigureNetworks < VagrantPlugins::GuestDebian::Cap::ConfigureNetworks

        def self.configure_networks(machine, networks)

          # Defer to Debian if guest uses 'eth*' network interfaces
          if machine.communicate.test("ip link | grep eth#{networks.first[:interface]}")
            return super
          end

          # Generate a text list of ethernet interfaces that
          # do not have IP address assigned to them.
          open_interfaces = ''
          machine.communicate.execute('diff <(ifconfig -a | cut -c 1-8 | sed "/^$/d" | uniq -u) <(ifconfig | cut -c 1-8 | sed "/^$/d" | uniq -u) | grep \<') do |type, data|
            open_interfaces = data.chomp if type == :stdout
          end

          # Convert the text list into an array, also cleaning up
          # the "< " from the `diff` command
          available_interfaces = []
          open_interfaces.lines.each do |line|
            iface = line[1..-1].strip
            available_interfaces << iface
          end

          # We need the main interface for DHCP, see GH-2648
          main_interface = ''
          machine.communicate.execute('ifconfig | cut -c 1-8 | sed "/^$/d" | uniq -u | sed "/lo/d"') do |type, data|
            main_interface = data.chomp if type == :stdout
          end


          machine.communicate.tap do |comm|
            # First, remove any previous network modifications
            # from the interface file.
            comm.sudo("sed -e '/^#VAGRANT-BEGIN/,$ d' /etc/network/interfaces > /tmp/vagrant-network-interfaces.pre")
            comm.sudo("sed -ne '/^#VAGRANT-END/,$ p' /etc/network/interfaces | tac | sed -e '/^#VAGRANT-END/,$ d' | tac > /tmp/vagrant-network-interfaces.post")


            # Accumulate the configurations to add to the interfaces file as
            # well as what interfaces we're actually configuring since we use that
            # later.
            interfaces = Set.new
            entries = []
            networks.each do |network|
              interface = available_interfaces.slice!(0)
              interfaces.add(interface)
              network[:interface] = interface
              entry = TemplateRenderer.render("guests/ubuntu/network_#{network[:type]}",
                                              options: network,
                                              main_interface: main_interface)

              entries << entry
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
              comm.sudo("/sbin/ifdown #{interface} 2> /dev/null")
              comm.sudo("/sbin/ip addr flush dev #{interface} 2> /dev/null")
            end

            comm.sudo('cat /tmp/vagrant-network-interfaces.pre /tmp/vagrant-network-entry /tmp/vagrant-network-interfaces.post > /etc/network/interfaces')
            comm.sudo('rm -f /tmp/vagrant-network-interfaces.pre /tmp/vagrant-network-entry /tmp/vagrant-network-interfaces.post')

            # Bring back up each network interface, reconfigured
            interfaces.each do |interface|
              comm.sudo("/sbin/ifup #{interface}")
            end
          end
        end
      end
    end
  end
end
