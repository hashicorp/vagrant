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
        attr_accessor :device

        def initialize
          @halt_timeout = 30
          @halt_check_interval = 1
          @suexec_cmd = 'sudo'
          @device = "e1000g"
        end
      end

      # Here for whenever it may be used.
      class SolarisError < Errors::VagrantError
        error_namespace("vagrant.systems.solaris")
      end

      def prepare_host_only_network(net_options=nil)
      end

      def enable_host_only_network(net_options)
        device = "#{vm.config.solaris.device}#{net_options[:adapter]}"
        su_cmd = vm.config.solaris.suexec_cmd
        ifconfig_cmd = "#{su_cmd} /sbin/ifconfig #{device}"
        vm.ssh.execute do |ssh|
          ssh.exec!("#{ifconfig_cmd} plumb")
          ssh.exec!("#{ifconfig_cmd} inet #{net_options[:ip]} netmask #{net_options[:netmask]}")
          ssh.exec!("#{ifconfig_cmd} up")
          ssh.exec!("#{su_cmd} sh -c \"echo '#{net_options[:ip]}' > /etc/hostname.#{device}\"")
        end
      end

      def change_host_name(name)
        su_cmd = vm.config.solaris.suexec_cmd
        vm.ssh.execute do |ssh|
          # Only do this if the hostname is not already set
          if !ssh.test?("#{su_cmd} hostname | grep '#{name}'")
            ssh.exec!("#{su_cmd} sh -c \"echo '#{name}' > /etc/nodename\"")
            ssh.exec!("#{su_cmd} uname -S #{name}")
          end
        end
      end


      # There should be an exception raised if the line
      #
      #     vagrant::::profiles=Primary Administrator
      #
      # does not exist in /etc/user_attr. TODO
      def halt
        vm.env.ui.info I18n.t("vagrant.systems.solaris.attempting_halt")
        vm.ssh.execute do |ssh|
          # Wait until the VM's state is actually powered off. If this doesn't
          # occur within a reasonable amount of time (15 seconds by default),
          # then simply return and allow Vagrant to kill the machine.
          count = 0
          last_error = nil
          while vm.vm.state != :powered_off
            begin
              ssh.exec!("#{vm.config.solaris.suexec_cmd} /usr/sbin/poweroff")
            rescue IOError => e
              # Save the last error; if it's not shutdown in a reasonable amount
              # of attempts we will re-raise the error so it's not hidden for
              # all time
              last_error = e
            end

            count += 1
            if count >= vm.config.solaris.halt_timeout
              # Check for last error and re-raise it
              if last_error != nil
                raise last_error
              else
                # Otherwise, just return
                return
              end
            end

            # Still opportunities remaining; sleep and loop
            sleep vm.config.solaris.halt_check_interval
          end # while
        end # do
      end

      def mount_shared_folder(ssh, name, guestpath, owner, group)
        # Create the shared folder
        ssh.exec!("#{vm.config.solaris.suexec_cmd} mkdir -p #{guestpath}")

        # Mount the folder with the proper owner/group
        options = "-o uid=`id -u #{owner}`,gid=`id -g #{group}`"
        ssh.exec!("#{vm.config.solaris.suexec_cmd} /sbin/mount -F vboxfs #{options} #{name} #{guestpath}")

        # chown the folder to the proper owner/group
        ssh.exec!("#{vm.config.solaris.suexec_cmd} chown `id -u #{owner}`:`id -g #{group}` #{guestpath}")
      end
    end
  end
end
