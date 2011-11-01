require 'vagrant/systems/linux/error'
require 'vagrant/systems/linux/config'

module Vagrant
  module Systems
    class Linux < Base

    include Util::Retryable

      def distro_dispatch
        # Can't detect the distro, Assumes unknown and raises an error.
        vm.env.config.vm.distribution
      end

      def halt
        vm.env.ui.info I18n.t("vagrant.systems.linux.attempting_halt")
        vm.ssh.execute do |ssh|
          ssh.exec!("sudo halt")
        end

        # Wait until the VM's state is actually powered off. If this doesn't
        # occur within a reasonable amount of time (15 seconds by default),
        # then simply return and allow Vagrant to kill the machine.
        count = 0
        while vm.vm.state != :powered_off
          count += 1

          return if count >= vm.env.config.linux.halt_timeout
          sleep vm.env.config.linux.halt_check_interval
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

        ssh.exec!("sudo rm -rf /media/sf_veewee-validation") # cleanup any veewee cruft using the default VirtualBox mount pattern
        ssh.exec!("if mountpoint -q  #{name}; then  sudo umount -t vboxsf #{name}; fi" )  # somehow a mount can already exist

        begin
          Timeout.timeout(ssh.aruba_timeout) do
            retryable(:tries => 5, :on => [ChildProcess::TimeoutError, IOError, ::Vagrant::Errors::SSHUnavailable], :sleep => 1.0) do
              result = ssh.exec!("sudo mount -t vboxsf #{options} #{name} #{guestpath}")
            end
          end
        rescue Timeout::Error
          raise LinuxError, :mount_fail
        end
      end
    end
  end
end
