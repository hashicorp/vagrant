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

      def mount_shared_folder(ssh, name, guestpath)
        ssh.exec!("#{vm.env.config.solaris.suexec_cmd} mkdir -p #{guestpath}")
        # Using a custom mount method here; could use improvement.
        ssh.exec!("#{vm.env.config.solaris.suexec_cmd} /sbin/mount -F vboxfs #{name} #{guestpath}")
        ssh.exec!("#{vm.env.config.solaris.suexec_cmd} chown #{vm.env.config.ssh.username} #{guestpath}")
      end

      def change_host_name(name)
        vm.ssh.execute do |ssh|
          if !ssh.test?("hostname | grep '#{name}'")
            # Replace default hostname in /etc/hosts with new hostname.
            # Don't rely on GNU sed in Solaris as it often does not exist.
            ssh.exec!("sed s/`hostname`/'#{name}'/g /etc/inet/hosts > /tmp/etc_hosts.new")
            ssh.exec!("#{vm.env.config.solaris.suexec_cmd} mv /tmp/etc_hosts.new /etc/inet/hosts")
            ssh.exec!("#{vm.env.config.solaris.suexec_cmd} chmod 444 /etc/inet/hosts")
            ssh.exec!("echo '#{name}' | #{vm.env.config.solaris.suexec_cmd} tee /etc/nodename > /dev/null")
            ssh.exec!("#{vm.env.config.solaris.suexec_cmd} hostname #{name}")
            # A lot of things break after you change the hostname out from under
            # Solaris.
            ssh.exec!("svcadm restart name-service-cache system-log rpc/bind inetd console-login")
            # Wait for things to go into maintenance then clear them.
            sleep 5
            ssh.exec!("for i in `svcs | grep maintenance | awk '{ print $3 }'`;do svcadm clear $i; done")
          end
        end
      end
    end
  end
end
