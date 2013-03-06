require 'set'
require 'tempfile'

require "vagrant"
require 'vagrant/util/template_renderer'

require Vagrant.source_root.join("plugins/guests/linux/guest")

module VagrantPlugins
  module GuestArch
    class Guest < VagrantPlugins::GuestLinux::Guest
      def initialize(*args)
        super
        if systemd?
          extend Systemd
        else
          extend SysVInit
        end
      end

      def systemd?
        vm.communicate.test("which systemctl &>/dev/null")
      end
      protected :systemd?

      module Systemd
        # Make the TemplateRenderer top-level
        include Vagrant::Util

        def change_host_name(name)
          # Only do this if the hostname is not already set
          if !vm.communicate.test("sudo hostname | grep '#{name}'")
            vm.communicate.sudo("hostnamectl set-hostname '#{name}'")
            vm.communicate.sudo("hostname '#{name}'")
          end
        end

        def configure_networks(networks)
          networks.each do |network|
            case network[:type]
            when :static
              vm.communicate.sudo("ip addr add #{network[:ip]}/#{network[:netmask]} dev eth#{network[:interface]}")
              vm.communicate.sudo("ip link set dev eth#{network[:interface]} up")
            when :dhcp
              vm.communicate.sudo("systemctl start dhcpcd@eth#{network[:interface]}")
            end
          end
        end

        def halt
          vm.communicate.sudo("systemctl poweroff")

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
          raise Vagrant::Errors::SSHDisconnected.new
        end
      end

      module SysVInit
        # Make the TemplateRenderer top-level
        include Vagrant::Util

        def change_host_name(name)
          # Only do this if the hostname is not already set
          if !vm.communicate.test("sudo hostname | grep '#{name}'")
            vm.communicate.sudo("sed -i 's/\\(HOSTNAME=\\).*/\\1#{name}/' /etc/rc.conf")
            vm.communicate.sudo("hostname #{name}")
            vm.communicate.sudo("sed -i 's@^\\(127[.]0[.]0[.]1[[:space:]]\\+\\)@\\1#{name} @' /etc/hosts")
          end
        end

        def configure_networks(networks)
          networks.each do |network|
            entry = TemplateRenderer.render("guests/arch/network_#{network[:type]}",
                                            :options => network)

            temp = Tempfile.new("vagrant")
            temp.binmode
            temp.write(entry)
            temp.close

            vm.communicate.upload(temp.path, "/tmp/vagrant_network")
            vm.communicate.sudo("mv /tmp/vagrant_network /etc/network.d/interfaces/eth#{network[:interface]}")
            vm.communicate.sudo("netcfg interfaces/eth#{network[:interface]}")
          end
        end
      end
    end
  end
end
