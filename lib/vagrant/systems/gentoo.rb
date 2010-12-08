module Vagrant
  module Systems
   class Gentoo < Base
      # A custom config class which will be made accessible via `config.gentoo`.
      class GentooConfig < Vagrant::Config::Base
        configures :gentoo

        attr_accessor :halt_timeout
        attr_accessor :halt_check_interval

        def initialize
          @halt_timeout = 30
          @halt_check_interval = 1
        end
      end

      #-------------------------------------------------------------------
      # Overridden methods
      #-------------------------------------------------------------------
      def halt
        vm.env.ui.info I18n.t("vagrant.systems.gentoo.attempting_halt")
        vm.ssh.execute do |ssh|
          ssh.exec!("sudo halt")
        end

        # Wait until the VM's state is actually powered off. If this doesn't
        # occur within a reasonable amount of time (15 seconds by default),
        # then simply return and allow Vagrant to kill the machine.
        count = 0
        while vm.vm.state != :powered_off
          count += 1

          return if count >= vm.env.config.gentoo.halt_timeout
          sleep vm.env.config.gentoo.halt_check_interval
        end
      end

      def mount_shared_folder(ssh, name, guestpath)
        ssh.exec!("sudo mkdir -p #{guestpath}")
        mount_folder(ssh, name, guestpath)
        ssh.exec!("sudo chown #{vm.env.config.ssh.username} #{guestpath}")
      end

      def mount_nfs(ip, folders)
        # TODO: Maybe check for nfs support on the guest, since its often
        # not installed by default
        folders.each do |name, opts|
          vm.ssh.execute do |ssh|
            ssh.exec!("sudo mkdir -p #{opts[:guestpath]}")
            ssh.exec!("sudo mount #{ip}:#{opts[:hostpath]} #{opts[:guestpath]}")
          end
        end
      end

      def prepare_host_only_network
        # Remove any previous host only network additions to the
        # interface file.
        vm.ssh.execute do |ssh|
          # Verify gentoo
          ssh.exec!("cat /etc/gentoo-release", :error_class => GentooError, :_key => :network_not_gentoo)

          # Clear out any previous entries
          ssh.exec!("sudo sed -e '/^#VAGRANT-BEGIN/,/^#VAGRANT-END/ d' /etc/conf.d/net > /tmp/vagrant-network-interfaces")
          ssh.exec!("sudo su -c 'cat /tmp/vagrant-network-interfaces > /etc/conf.d/net'")
        end
      end

      def enable_host_only_network(net_options)
        entry = TemplateRenderer.render('network_entry_gentoo', :net_options => net_options)
        vm.ssh.upload!(StringIO.new(entry), "/tmp/vagrant-network-entry")

        vm.ssh.execute do |ssh|
          ssh.exec!("sudo ln -s /etc/init.d/net.lo /etc/init.d/net.eth#{net_options[:adapter]}")
          ssh.exec!("sudo /etc/init.d/net.eth#{net_options[:adapter]} stop 2> /dev/null")
          ssh.exec!("sudo su -c 'cat /tmp/vagrant-network-entry >> /etc/conf.d/net'")
          ssh.exec!("sudo /etc/init.d/net.eth#{net_options[:adapter]} start")
        end
      end

      #-------------------------------------------------------------------
      # "Private" methods which assist above methods
      #-------------------------------------------------------------------
      def mount_folder(ssh, name, guestpath, sleeptime=5)
        # Determine the permission string to attach to the mount command
        perms = []
        perms << "uid=#{vm.env.config.vm.shared_folder_uid}"
        perms << "gid=#{vm.env.config.vm.shared_folder_gid}"
        perms = " -o #{perms.join(",")}" if !perms.empty?

        attempts = 0
        while true
          result = ssh.exec!("sudo mount -t vboxsf#{perms} #{name} #{guestpath}") do |ch, type, data|
            # net/ssh returns the value in ch[:result] (based on looking at source)
            ch[:result] = !!(type == :stderr && data =~ /No such device/i)
          end

          break unless result

          attempts += 1
          raise GentooError.new(:mount_fail) if attempts >= 10
          sleep sleeptime
        end
      end
    end

    class Gentoo < Base
      class GentooError < Errors::VagrantError
        error_namespace("vagrant.systems.gentoo")
      end
    end
  end
end

