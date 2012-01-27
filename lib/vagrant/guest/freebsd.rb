module Vagrant
  module Guest
    # A general Vagrant system implementation for "freebsd".
    #
    # Contributed by Kenneth Vestergaard <kvs@binarysolutions.dk>
    class FreeBSD < Base
      # A custom config class which will be made accessible via `config.freebsd`
      # This is not necessary for all system implementers, of course. However,
      # generally, Vagrant tries to make almost every aspect of its execution
      # configurable, and this assists that goal.
      class FreeBSDConfig < Vagrant::Config::Base
        attr_accessor :halt_timeout
        attr_accessor :halt_check_interval

        def initialize
          @halt_timeout = 30
          @halt_check_interval = 1
        end
      end

      # Here for whenever it may be used.
      class FreeBSDError < Errors::VagrantError
        error_namespace("vagrant.guest.freebsd")
      end

      def halt
        vm.channel.sudo("shutdown -p now")

        # Wait until the VM's state is actually powered off. If this doesn't
        # occur within a reasonable amount of time (15 seconds by default),
        # then simply return and allow Vagrant to kill the machine.
        count = 0
        while vm.state != :poweroff
          count += 1

          return if count >= vm.config.freebsd.halt_timeout
          sleep vm.config.freebsd.halt_check_interval
        end
      end

      # TODO: vboxsf is currently unsupported in FreeBSD, if you are able to
      # help out with this project, please contact vbox@FreeBSD.org
      #
      # See: http://wiki.freebsd.org/VirtualBox/ToDo
      # def mount_shared_folder(ssh, name, guestpath)
      #   ssh.exec!("sudo mkdir -p #{guestpath}")
      #   # Using a custom mount method here; could use improvement.
      #   ssh.exec!("sudo mount -t vboxfs v-root #{guestpath}")
      #   ssh.exec!("sudo chown #{vm.config.ssh.username} #{guestpath}")
      # end

      def mount_nfs(ip, folders)
        folders.each do |name, opts|
          vm.channel.sudo("mkdir -p #{opts[:guestpath]}")
          vm.channel.sudo("mount #{ip}:#{opts[:hostpath]} #{opts[:guestpath]}")
        end
      end

      def configure_networks(networks)
        # Remove any previous host only network additions to the
        # interface file.
        vm.channel.sudo("sed -e '/^#VAGRANT-BEGIN-HOSTONLY/,/^#VAGRANT-END-HOSTONLY/ d' /etc/rc.conf > /tmp/rc.conf")
        vm.channel.sudo("mv /tmp/rc.conf /etc/rc.conf")

        networks.each do |network|
          entry = "#VAGRANT-BEGIN-HOSTONLY\nifconfig_em#{network[:interface]}=\"inet #{network[:ip]} netmask #{network[:netmask]}\"\n#VAGRANT-END-HOSTONLY\n"
          vm.channel.upload(StringIO.new(entry), "/tmp/vagrant-network-entry")

          vm.channel.sudo("su -m root -c 'cat /tmp/vagrant-network-entry >> /etc/rc.conf'")
          vm.channel.sudo("ifconfig em#{network[:interface]} inet #{network[:ip]} netmask #{network[:netmask]}")
        end
      end
    end
  end
end
