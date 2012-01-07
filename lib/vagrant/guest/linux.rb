require 'vagrant/guest/linux/error'
require 'vagrant/guest/linux/config'

module Vagrant
  module Guest
    class Linux < Base
      def distro_dispatch
        if @vm.channel.execute("cat /etc/debian_version") == 0
          return :debian if @vm.channel.execute("cat /proc/version | grep 'Debian'") == 0
          return :ubuntu if @vm.channel.execute("cat /proc/version | grep 'Ubuntu'") == 0
        end

        return :gentoo if @vm.channel.execute("cat /etc/gentoo-release") == 0
        return :redhat if @vm.channel.execute("cat /etc/redhat-release") == 0
        return :suse if @vm.channel.execute("cat /etc/SuSE-release") == 0
        return :arch if @vm.channel.execute("cat /etc/arch-release") == 0

        # Can't detect the distro, assume vanilla linux
        nil
      end

      def halt
        vm.ui.info I18n.t("vagrant.guest.linux.attempting_halt")
        vm.ssh.execute do |ssh|
          ssh.exec!("sudo shutdown -h now")
        end

        # Wait until the VM's state is actually powered off. If this doesn't
        # occur within a reasonable amount of time (15 seconds by default),
        # then simply return and allow Vagrant to kill the machine.
        count = 0
        while vm.state != :poweroff
          count += 1

          return if count >= vm.config.linux.halt_timeout
          sleep vm.config.linux.halt_check_interval
        end
      end

      def mount_shared_folder(name, guestpath, owner, group)
        @vm.channel.sudo("mkdir -p #{guestpath}")
        mount_folder(name, guestpath, owner, group)
        @vm.channel.sudo("chown `id -u #{owner}`:`id -g #{group}` #{guestpath}")
      end

      def mount_nfs(ip, folders)
        # TODO: Maybe check for nfs support on the guest, since its often
        # not installed by default
        folders.each do |name, opts|
          vm.ssh.execute do |ssh|
            ssh.exec!("sudo mkdir -p #{opts[:guestpath]}")
            ssh.exec!("sudo mount #{ip}:'#{opts[:hostpath]}' #{opts[:guestpath]}", :_error_class => LinuxError, :_key => :mount_nfs_fail)
          end
        end
      end

      #-------------------------------------------------------------------
      # "Private" methods which assist above methods
      #-------------------------------------------------------------------
      def mount_folder(name, guestpath, owner, group, sleeptime=5)
        # Determine the permission string to attach to the mount command
        options = "-o uid=`id -u #{owner}`,gid=`id -g #{group}`"

        attempts = 0
        while true
          success = true
          @vm.channel.sudo("mount -t vboxsf #{options} #{name} #{guestpath}") do |type, data|
            success = false if type == :stderr && data =~ /No such device/i
          end

          break if success

          attempts += 1
          raise LinuxError, :mount_fail if attempts >= 10
          sleep sleeptime
        end
      end
    end
  end
end
