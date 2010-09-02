module Vagrant
  module Systems
    # A general Vagrant system implementation for "solaris".
    class solaris < Base
      # A custom config class which will be made accessible via `config.solaris`
      # This is not necessary for all system implementers, of course. However,
      # generally, Vagrant tries to make almost every aspect of its execution
      # configurable, and this assists that goal.
      # 
      # Contributed by Blake Irvin <b.irvin@modcloth.com>
      #
      class SolarisConfig < Vagrant::Config::Base
        attr_accessor :halt_timeout
        attr_accessor :halt_check_interval

        def initialize
          @halt_timeout = 30
          @halt_check_interval = 1
        end
      end

      # Register config class
      Config.configures :solaris, SolarisConfig

      #-------------------------------------------------------------------
      # Overridden methods
      #-------------------------------------------------------------------
      # There should be an exception raised if the line
      # vagrant::::profiles=Primary Administrator
      # does not exist in /etc/user_attr - but I'm not sure how to best
      # do that.
      def halt
        vm.env.ui.info "vagrant.systems.solaris.attempting_halt"
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
        ssh.exec!("pfexec mount -F vboxfs v-root #{guestpath}"
        ssh.exec!("pfexec chown #{config.ssh.username} #{guestpath}")
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
          raise SolarisError.new(:mount_fail) if attempts >= 10
          sleep sleeptime
        end
      end

      def config
        vm.env.config
      end
    end

    class Linux < Base
      class SolarisError < Errors::VagrantError
        error_namespace("vagrant.systems.solaris")
      end
    end
  end
end