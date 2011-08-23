
module Vagrant
  module Systems
    # A general Vagrant system implementation for "windows". Using this script
    # assumes that you built the box image with the SSHD daemon running
    # under Cygwin.
    #
    # Contributed by Gabe McArthur <madeonmac@gmail.com>
    class Windows < Base
      class WindowsConfig < Vagrant::Config::Base
        configures :windows

        attr_accessor :halt_timeout
        attr_accessor :halt_check_interval

        def initialize
          @halt_timeout = 30
          @halt_check_interval = 1
        end
      end

      class WindowsError < Errors::VagrantError
        error_namespace("vagrant.systems.windows")
      end

      def halt
        vm.env.ui.info I18n.t("vagrant.systems.windows.attempting_halt")
        vm.ssh.execute do |ssh|
          ssh.exec!('shutdown.exe /p /f')
        end

        # Wait until the VM's state is actually powered off. If this doesn't
        # occur within a reasonable amount of time (15 seconds by default),
        # then simply return and allow Vagrant to kill the machine.
        count = 0
        while vm.vm.state != :powered_off
          count += 1

          return if count >= vm.env.config.windows.halt_timeout
          sleep vm.env.config.windows.halt_check_interval
        end
      end

      # TODO: TEST
      #def mount_shared_folder(ssh, name, guestpath)
        # ssh.exec!("mkdir -p #{guestpath}")
        # Using a custom mount method here; could use improvement.
        # ssh.exec!("mount -t vboxfs #{guestpath}")
        # ssh.exec!("chown #{vm.env.config.ssh.username} #{guestpath}")
      #end

      # TODO: TEST
      #def mount_nfs(ip, folders)
      #  folders.each do |name, opts|
      #    vm.ssh.execute do |ssh|
      #      ssh.exec!("mkdir -p #{opts[:guestpath]}")
      #      ssh.exec!("mount #{ip}:#{opts[:hostpath]} #{opts[:guestpath]}")
      #    end
      #  end
      #end

      # TODO: TEST
      def change_host_name(name)
        vm.ssh.execute do |ssh|
          ssh.exec!("C:/Windows/System32/wbem/WMIC.exe computersystem where name=\"%COMPUTERNAME%\" call rename name=\"#{name}\"")
        end
        vm.env.ui.warn I18n.t("vagrant.systems.windows.rename_requires_restart")
      end

      # Prepares the system for host only networks. This is called
      # once prior to any `enable_host_only_network` calls.
      # TODO: TEST
      #def prepare_host_only_network(net_options=nil)
        # Remove any previous host only network additions to the
        # interface file.
      #  vm.ssh.execute do |ssh|
          # Clear out any previous entries
      #    ssh.exec!("sudo sed -e '/^#VAGRANT-BEGIN/,/^#VAGRANT-END/ d' /etc/rc.conf > /tmp/rc.conf")
      #    ssh.exec!("sudo mv /tmp/rc.conf /etc/rc.conf")
      #  end
      #end

      # Setup the system by adding a new host only network. This
      # method should configure and bring up the interface for the
      # given options.
      #
      # @param [Hash] net_options The options for the network.
      # TODO: TEST
      #def enable_host_only_network(net_options)
      #  entry = "#VAGRANT-BEGIN\nifconfig_em#{net_options[:adapter]}=\"inet #{net_options[:ip]} netmask #{net_options[:netmask]}\"\n#VAGRANT-END\n"
      #  vm.ssh.upload!(StringIO.new(entry), "/tmp/vagrant-network-entry")

      #  vm.ssh.execute do |ssh|
      #    ssh.exec!("sudo su -m root -c 'cat /tmp/vagrant-network-entry >> /etc/rc.conf'")
      #    ssh.exec!("sudo ifconfig em#{net_options[:adapter]} inet #{net_options[:ip]} netmask #{net_options[:netmask]}")
      #  end
      #end
    end
  end
end

