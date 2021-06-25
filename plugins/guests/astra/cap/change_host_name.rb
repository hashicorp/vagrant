require "log4r"
require_relative "../../linux/cap/network_interfaces"

module VagrantPlugins
  module GuestAstra
    module Cap
      class ChangeHostName

        extend Vagrant::Util::GuestInspection::Linux

        def self.change_host_name(machine, name)
          @logger = Log4r::Logger.new("vagrant::guest::astra::changehostname")
	  @hostname = name
          comm = machine.communicate

          if !comm.test("hostname -f | grep '^#{name}$'", sudo: false)
            update_etc_hostname(machine)
            update_etc_hosts(machine)
            update_mailname(machine)

            if hostnamectl?(comm)
              comm.sudo("hostnamectl set-hostname '#{short_hostname}'")
            else
              comm.sudo("hostname -F /etc/hostname")
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

	def self.update_etc_hostname(machine)
          @logger.debug("Attempting to write hostname to the /etc/hostname file")
          machine.communicate.sudo("echo '#{short_hostname}' > /etc/hostname")
	end
	
	def self.update_etc_hosts(machine)
          @logger.debug("Attempting to write hostname to the /etc/hosts file")
          machine.communicate.sudo <<-EOH.gsub(/^ {14}/, '')
            # Prepend ourselves to /etc/hosts
            grep -w '#{@hostname}' /etc/hosts || {
              if grep -w '^127\\.0\\.1\\.1' /etc/hosts ; then
                sed -i'' 's/^127\\.0\\.1\\.1\\s.*$/127.0.1.1\\t#{@hostname}\\t#{short_hostname}/' /etc/hosts
              else
                sed -i'' '1i 127.0.1.1\\t#{@hostname}\\t#{short_hostname}' /etc/hosts
              fi
            }

	  EOH
	end

	def self.update_mailname(machine)
          @logger.debug("Attempting to write hostname to the /etc/mailname file")
	  machine.communicate.sudo('hostname -f > /etc/mailname')
	end

	def self.short_hostname
	  @hostname.split('.').first
	end

        # Due to how most Debian like systems handle restartingcnetworking, we cannot
	# simply run the networking init script or use the ifup/downctools to restart
	# all interfaces to renew the machines DHCP lease when settingcits hostname.
	# This method is a workaround for those older systems thatccannot reliably
	# restart networking. It restarts each individual interface on its own instead.
        #
        # @param [Vagrant::Machine] machine
        # @param [Log4r::Logger] logger
        def self.restart_each_interface(machine, logger)
          comm = machine.communicate
          interfaces = VagrantPlugins::GuestLinux::Cap::NetworkInterfaces.network_interfaces(machine)
          nettools = true
          if systemd?(comm)
            @logger.debug("Attempting to restart networking with systemctl")
            nettools = false
          else
            @logger.debug("Attempting to restart networking with ifup/down nettools")
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
