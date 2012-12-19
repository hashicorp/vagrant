require 'set'
require 'tempfile'

require 'vagrant/util/template_renderer'

module Vagrant
  module Guest
    class Arch < Linux
      def initialize(*args)
        super
        if systemd?
          extend Systemd
        else
          extend SysVInit
        end
      end

      def systemd?
        vm.channel.test("which systemctl &>/dev/null")
      end
      protected :systemd?

      module Systemd
        # Make the TemplateRenderer top-level
        include Vagrant::Util

        def change_host_name(name)
          # Only do this if the hostname is not already set
          if !vm.channel.test("sudo hostname | grep '#{name}'")
            vm.channel.sudo("hostnamectl set-hostname #{name}")
            vm.channel.sudo("sed -i 's@^\\(127[.]0[.]0[.]1[[:space:]]\\+\\)@\\1#{name} @' /etc/hosts")
          end
        end

        def configure_networks(networks)
          networks.each do |network|
            case network[:type]
            when :static
              vm.channel.sudo("ip addr add #{network[:ip]}/#{network[:netmask]} dev eth#{network[:interface]}")
              vm.channel.sudo("ip link set dev eth#{network[:interface]} up")
            when :dhcp
              vm.channel.sudo("systemctl start dhcpcd@eth#{network[:interface]}")
            end
          end
        end

        def halt
          vm.channel.sudo("systemctl poweroff")

          # Wait until the VM's state is actually powered off. If this doesn't
          # occur within a reasonable amount of time (15 seconds by default),
          # then simply return and allow Vagrant to kill the machine.
          count = 0
          while vm.state != :poweroff
            count += 1

            return if count >= vm.config.linux.halt_timeout
            sleep vm.config.linux.halt_check_interval
          end
        rescue IOError
          raise Errors::SSHConnectionClosed.new
        end
      end

      module SysVInit
        # Make the TemplateRenderer top-level
        include Vagrant::Util

        def change_host_name(name)
          # Only do this if the hostname is not already set
          if !vm.channel.test("sudo hostname | grep '#{name}'")
            vm.channel.sudo("sed -i 's/\\(HOSTNAME=\\).*/\\1#{name}/' /etc/rc.conf")
            vm.channel.sudo("hostname #{name}")
            vm.channel.sudo("sed -i 's@^\\(127[.]0[.]0[.]1[[:space:]]\\+\\)@\\1#{name} @' /etc/hosts")
          end
        end

        def configure_networks(networks)
          # Remove previous Vagrant-managed network interfaces
          vm.channel.sudo("sed -e '/^#VAGRANT-BEGIN/,/^#VAGRANT-END/ d' /etc/rc.conf > /tmp/vagrant-network-interfaces")
          vm.channel.sudo("cat /tmp/vagrant-network-interfaces > /etc/rc.conf")

          # Configure the network interfaces
          interfaces = Set.new
          entries = []
          networks.each do |network|
            interfaces.add(network[:interface])
            entry = TemplateRenderer.render("guests/arch/network_#{network[:type]}",
                                            :options => network)

            entries << entry
          end

          # Perform the careful dance necessary to reconfigure
          # the network interfaces
          temp = Tempfile.new("vagrant")
          temp.binmode
          temp.write(entries.join("\n"))
          temp.close

          vm.channel.upload(temp.path, "/tmp/vagrant-network-entry")

          # Reconfigure the network interfaces
          vm.channel.sudo("cat /tmp/vagrant-network-entry >> /etc/rc.conf")
          vm.channel.sudo("/etc/rc.d/network restart")

          interfaces.each do |interface|
            vm.channel.sudo("dhcpcd -k eth#{interface} && dhcpcd eth#{interface} && sleep 3")
          end
        end
      end
    end
  end
end
