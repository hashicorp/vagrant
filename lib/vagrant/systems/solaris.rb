module Vagrant
  module Systems
    # A general Vagrant system implementation for "solaris".
    #
    # Contributed by Blake Irvin <b.irvin@modcloth.com>
    class Solaris < Base
      # A custom config class which will be made accessible via `config.solaris`
      # This is not necessary for all system implementers, of course. However,
      # generally, Vagrant tries to make almost every aspect of its execution
      # configurable, and this assists that goal.
      class SolarisConfig < Vagrant::Config::Base
        configures :solaris

        attr_accessor :halt_timeout
        attr_accessor :halt_check_interval
        # This sets the command to use to execute items as a superuser. sudo is default
        attr_accessor :suexec_cmd

        def initialize
          @halt_timeout = 30
          @halt_check_interval = 1
          @suexec_cmd = 'sudo'
        end
      end

      # Here for whenever it may be used.
      class SolarisError < Errors::VagrantError
        error_namespace("vagrant.systems.solaris")
      end

      # There should be an exception raised if the line
      #
      #     vagrant::::profiles=Primary Administrator
      #
      # does not exist in /etc/user_attr. TODO
      def halt
        vm.env.ui.info I18n.t("vagrant.systems.solaris.attempting_halt")
        vm.ssh.execute do |ssh|
          ssh.exec!("#{vm.env.config.solaris.suexec_cmd} /usr/sbin/poweroff")
        end

        # Wait until the VM's state is actually powered off. If this doesn't
        # occur within a reasonable amount of time (15 seconds by default),
        # then simply return and allow Vagrant to kill the machine.
        count = 0
        while vm.vm.state != :powered_off
          count += 1

          return if count >= vm.env.config.solaris.halt_timeout
          sleep vm.env.config.solaris.halt_check_interval
        end
      end

      def mount_shared_folder(ssh, name, guestpath, owner, group)
        # Create the shared folder
        ssh.exec!("#{vm.env.config.solaris.suexec_cmd} mkdir -p #{guestpath}")

        # Mount the folder with the proper owner/group
        options = "-o uid=`id -u #{owner}`,gid=`id -g #{group}`"
        ssh.exec!("#{vm.env.config.solaris.suexec_cmd} /sbin/mount -F vboxfs #{options} #{name} #{guestpath}")

        # chown the folder to the proper owner/group
        ssh.exec!("#{vm.env.config.solaris.suexec_cmd} chown `id -u #{owner}`:`id -g #{group}` #{guestpath}")
      end
    end
  end
end
