require "log4r"
require 'vagrant/util/guest_hosts'
require 'vagrant/util/guest_inspection'
require_relative "../../linux/cap/network_interfaces"

module VagrantPlugins
  module GuestDebian
    module Cap
      class ChangeHostName

        extend Vagrant::Util::GuestInspection::Linux
        extend Vagrant::Util::GuestHosts::Linux

        def self.change_host_name(machine, name)
          @logger = Log4r::Logger.new("vagrant::guest::debian::changehostname")
          comm = machine.communicate

          if !comm.test("hostname -f | grep '^#{name}$'", sudo: false)
            network_with_hostname = machine.config.vm.networks.map {|_, c| c if c[:hostname] }.compact[0]
            if network_with_hostname
              replace_host(comm, name, network_with_hostname[:ip])
            else
              add_hostname_to_loopback_interface(comm, name)
            end

            basename = name.split(".", 2)[0]
            comm.sudo <<-EOH.gsub(/^ {14}/, '')
              # Set the hostname
              echo '#{basename}' > /etc/hostname

              # Update mailname
              echo '#{name}' > /etc/mailname

            EOH

            if hostnamectl?(comm)
              comm.sudo("hostnamectl set-hostname '#{basename}'")
            else
              comm.sudo <<-EOH.gsub(/^ {14}/, '')
              hostname -F /etc/hostname
              # Restart hostname services
              if test -f /etc/init.d/hostname; then
                /etc/init.d/hostname start || true
              fi

              if test -f /etc/init.d/hostname.sh; then
                /etc/init.d/hostname.sh start || true
              fi
              EOH
            end

            restart_command = nil
            if systemd?(comm)
              if systemd_networkd?(comm)
                @logger.debug("Attempting to restart networking with systemd-networkd")
                restart_command = "systemctl restart systemd-networkd.service"
              elsif systemd_controlled?(comm, "NetworkManager.service")
                @logger.debug("Attempting to restart networking with NetworkManager")
                restart_command = "systemctl restart NetworkManager.service"
              end
            end

            if restart_command
              comm.sudo(restart_command)
            else
              restart_each_interface(machine, @logger)
            end
          end
        end

        protected

        # Due to how most Debian systems and older Ubuntu systems handle restarting
        # networking, we cannot simply run the networking init script or use the ifup/down
        # tools to restart all interfaces to renew the machines DHCP lease when setting
        # its hostname. This method is a workaround for those older systems that
        # cannoy reliably restart networking. It restarts each individual interface
        # on its own instead.
        #
        # @param [Vagrant::Machine] machine
        # @param [Log4r::Logger] logger
        def self.restart_each_interface(machine, logger)
          comm = machine.communicate
          interfaces = VagrantPlugins::GuestLinux::Cap::NetworkInterfaces.network_interfaces(machine)
          nettools = true
          if systemd?(comm)
            logger.debug("Attempting to restart networking with systemctl")
            nettools = false
          else
            logger.debug("Attempting to restart networking with ifup/down nettools")
          end

          interfaces.each do |iface|
            logger.debug("Restarting interface #{iface} on guest #{machine.name}")
            if nettools
             restart_command = "ifdown #{iface};ifup #{iface}"
            else
             restart_command = "systemctl stop ifup@#{iface}.service;systemctl start ifup@#{iface}.service"
            end
            comm.sudo(restart_command)
          end
        end
      end
    end
  end
end
