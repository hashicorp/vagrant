require 'vagrant/systems/linux/error'
require 'vagrant/systems/linux/config'

module Vagrant
  module Systems
    class Linux < Base
      def distro_dispatch
        vm.ssh.execute do |ssh|
          if ssh.test?("cat /etc/debian_version")
            return :debian if ssh.test?("cat /proc/version | grep 'Debian'")
            return :ubuntu if ssh.test?("cat /proc/version | grep 'Ubuntu'")
          end

          return :gentoo if ssh.test?("cat /etc/gentoo-release")
          return :redhat if ssh.test?("cat /etc/redhat-release")
          return :suse if ssh.test?("cat /etc/SuSE-release")
          return :arch if ssh.test?("cat /etc/arch-release")
        end

        # Can't detect the distro, assume vanilla linux
        nil
      end

      def halt
        vm.env.ui.info I18n.t("vagrant.systems.linux.attempting_halt")
        vm.ssh.execute do |ssh|
          ssh.exec!("sudo shutdown -h now")
        end

        # Wait until the VM's state is actually powered off. If this doesn't
        # occur within a reasonable amount of time (15 seconds by default),
        # then simply return and allow Vagrant to kill the machine.
        count = 0
        while vm.vm.state != :powered_off
          count += 1

          return if count >= vm.config.linux.halt_timeout
          sleep vm.config.linux.halt_check_interval
        end
      end

      def mount_shared_folder(ssh, name, guestpath, owner, group)
        ssh.exec!("sudo mkdir -p #{guestpath}")
        mount_folder(ssh, name, guestpath, owner, group)
        ssh.exec!("sudo chown `id -u #{owner}`:`id -g #{group}` #{guestpath}")
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
      def mount_folder(ssh, name, guestpath, owner, group, sleeptime=5)
        # Determine the permission string to attach to the mount command
        options = "-o uid=`id -u #{owner}`,gid=`id -g #{group}`"

        attempts = 0
        while true
          result = ssh.exec!("sudo mount -t vboxsf #{options} #{name} #{guestpath}") do |ch, type, data|
            # net/ssh returns the value in ch[:result] (based on looking at source)
            ch[:result] = !!(type == :stderr && data =~ /No such device/i)
          end

          break unless result

          attempts += 1
          raise LinuxError, :mount_fail if attempts >= 10
          sleep sleeptime
        end
      end
    end
  end
end
