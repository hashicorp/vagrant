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

        def initialize
          @halt_timeout = 30
          @halt_check_interval = 1
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
          ssh.exec!("pfexec poweroff")
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
        ssh.exec!("pfexec mkdir -p #{guestpath}")
        # Using a custom mount method here; could use improvement.
        ssh.exec!("pfexec mount -F vboxfs v-root #{guestpath}")
        ssh.exec!("pfexec chown #{vm.env.config.ssh.username} #{guestpath}")
      end
    end
  end
end
