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
        vm.ui.info I18n.t("vagrant.guest.freebsd.attempting_halt")
        vm.ssh.execute do |ssh|
          ssh.exec!("sudo shutdown -p now")
        end

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

      # TODO: Error/warning about this.
      # def mount_shared_folder(ssh, name, guestpath)
      #   ssh.exec!("sudo mkdir -p #{guestpath}")
      #   # Using a custom mount method here; could use improvement.
      #   ssh.exec!("sudo mount -t vboxfs v-root #{guestpath}")
      #   ssh.exec!("sudo chown #{vm.config.ssh.username} #{guestpath}")
      # end

      def mount_nfs(ip, folders)
        folders.each do |name, opts|
          vm.ssh.execute do |ssh|
            ssh.exec!("sudo mkdir -p #{opts[:guestpath]}")
            ssh.exec!("sudo mount #{ip}:#{opts[:hostpath]} #{opts[:guestpath]}")
          end
        end
      end

      def prepare_host_only_network(net_options=nil)
        # Remove any previous host only network additions to the
        # interface file.
        vm.ssh.execute do |ssh|
          # Clear out any previous entries
          ssh.exec!("sudo sed -e '/^#VAGRANT-BEGIN/,/^#VAGRANT-END/ d' /etc/rc.conf > /tmp/rc.conf")
          ssh.exec!("sudo mv /tmp/rc.conf /etc/rc.conf")
        end
      end

      def enable_host_only_network(net_options)
        entry = "#VAGRANT-BEGIN\nifconfig_em#{net_options[:adapter]}=\"inet #{net_options[:ip]} netmask #{net_options[:netmask]}\"\n#VAGRANT-END\n"
        vm.ssh.upload!(StringIO.new(entry), "/tmp/vagrant-network-entry")

        vm.ssh.execute do |ssh|
          ssh.exec!("sudo su -m root -c 'cat /tmp/vagrant-network-entry >> /etc/rc.conf'")
          ssh.exec!("sudo ifconfig em#{net_options[:adapter]} inet #{net_options[:ip]} netmask #{net_options[:netmask]}")
        end
      end
    end
  end
end
