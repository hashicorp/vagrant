module Vagrant
  module Guest
    # A general Vagrant system implementation for "solaris".
    #
    # Contributed by Blake Irvin <b.irvin@modcloth.com>
    class Solaris < Base
      # A custom config class which will be made accessible via `config.solaris`
      # This is not necessary for all system implementers, of course. However,
      # generally, Vagrant tries to make almost every aspect of its execution
      # configurable, and this assists that goal.
      class SolarisConfig < Vagrant::Config::Base
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
        error_namespace("vagrant.guest.solaris")
      end

      def configure_networks(networks)
        networks.each do |network|
          device = "#{vm.config.solaris.device}#{network[:interface]}"
          su_cmd = vm.config.solaris.suexec_cmd
          ifconfig_cmd = "#{su_cmd} /sbin/ifconfig #{device}"

          vm.channel.execute("#{ifconfig_cmd} plumb")

          if network[:type].to_sym == :static
            vm.channel.execute("#{ifconfig_cmd} inet #{network[:ip]} netmask #{network[:netmask]}")
            vm.channel.execute("#{ifconfig_cmd} up")
            vm.channel.execute("#{su_cmd} sh -c \"echo '#{network[:ip]}' > /etc/hostname.#{device}\"")
          elsif network[:type].to_sym == :dhcp
            vm.channel.execute("#{ifconfig_cmd} dhcp start")
          end
        end
      end

      def change_host_name(name)
        su_cmd = vm.config.solaris.suexec_cmd

        # Only do this if the hostname is not already set
        if !vm.channel.test("#{su_cmd} hostname | grep '#{name}'")
          vm.channel.execute("#{su_cmd} sh -c \"echo '#{name}' > /etc/nodename\"")
          vm.channel.execute("#{su_cmd} uname -S #{name}")
        end
      end

      # There should be an exception raised if the line
      #
      #     vagrant::::profiles=Primary Administrator
      #
      # does not exist in /etc/user_attr. TODO
      def halt
        # Wait until the VM's state is actually powered off. If this doesn't
        # occur within a reasonable amount of time (15 seconds by default),
        # then simply return and allow Vagrant to kill the machine.
        count = 0
        last_error = nil
        while vm.state != :poweroff
          begin
            vm.channel.execute("#{vm.config.solaris.suexec_cmd} /usr/sbin/poweroff")
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
      end

      def mount_shared_folder(name, guestpath, options)
        # These are just far easier to use than the full options syntax
        owner = options[:owner]
        group = options[:group]

        # Create the shared folder
        vm.channel.execute("#{vm.config.solaris.suexec_cmd} mkdir -p #{guestpath}")

        # Mount the folder with the proper owner/group
        mount_options = "-o uid=`id -u #{owner}`,gid=`id -g #{group}`"
        mount_options += ",#{options[:extra]}" if options[:extra]
        vm.channel.execute("#{vm.config.solaris.suexec_cmd} /sbin/mount -F vboxfs #{mount_options} #{name} #{guestpath}")

        # chown the folder to the proper owner/group
        vm.channel.execute("#{vm.config.solaris.suexec_cmd} chown `id -u #{owner}`:`id -g #{group}` #{guestpath}")
      end
    end
  end
end
