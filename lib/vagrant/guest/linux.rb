require 'log4r'

require 'vagrant/guest/linux/error'
require 'vagrant/guest/linux/config'

module Vagrant
  module Guest
    class Linux < Base
      def initialize(*args)
        super

        @logger = Log4r::Logger.new("vagrant::guest::linux")
      end

      def distro_dispatch
        if @vm.channel.test("cat /etc/debian_version")
          return :debian if @vm.channel.test("cat /proc/version | grep 'Debian'")
          return :ubuntu if @vm.channel.test("cat /proc/version | grep 'Ubuntu'")
        end

        return :gentoo if @vm.channel.test("cat /etc/gentoo-release")
        return :redhat if @vm.channel.test("cat /etc/redhat-release")
        return :suse if @vm.channel.test("cat /etc/SuSE-release")
        return :arch if @vm.channel.test("cat /etc/arch-release")

        # Can't detect the distro, assume vanilla linux
        nil
      end

      def halt
        @vm.channel.sudo("shutdown -h now")

        # Wait until the VM's state is actually powered off. If this doesn't
        # occur within a reasonable amount of time (15 seconds by default),
        # then simply return and allow Vagrant to kill the machine.
        count = 0
        while @vm.state != :poweroff
          count += 1

          return if count >= @vm.config.linux.halt_timeout
          sleep @vm.config.linux.halt_check_interval
        end
      end

      def mount_shared_folder(name, guestpath, options)
        real_guestpath = expanded_guest_path(guestpath)
        @logger.debug("Shell expanded guest path: #{real_guestpath}")

        @vm.channel.sudo("mkdir -p #{real_guestpath}")
        mount_folder(name, real_guestpath, options)
        @vm.channel.sudo("chown `id -u #{options[:owner]}`:`id -g #{options[:group]}` #{real_guestpath}")
      end

      def mount_nfs(ip, folders)
        # TODO: Maybe check for nfs support on the guest, since its often
        # not installed by default
        folders.each do |name, opts|
          # Expand the guestpath, so we can handle things like "~/vagrant"
          real_guestpath = expanded_guest_path(opts[:guestpath])

          # Do the actual creating and mounting
          @vm.channel.sudo("mkdir -p #{real_guestpath}")
          @vm.channel.sudo("mount -o vers=#{opts[:nfs_version]} #{ip}:'#{opts[:hostpath]}' #{real_guestpath}",
                          :error_class => LinuxError,
                          :error_key => :mount_nfs_fail)
        end
      end

      protected

      # Determine the real guest path. Since we use a `sudo` shell everywhere
      # else, things like '~' don't expand properly in shared folders. We have
      # to `echo` here to get that path.
      #
      # @param [String] guestpath The unexpanded guest path.
      # @return [String] The expanded guestpath
      def expanded_guest_path(guestpath)
        real_guestpath = nil
        @vm.channel.execute("printf #{guestpath}") do |type, data|
          if type == :stdout
            real_guestpath ||= ""
            real_guestpath += data
          end
        end

        if !real_guestpath
          # Really strange error case if this happens. Let's throw an error,
          # tell the user to check the echo output.
          raise LinuxError, :_key => :guestpath_expand_fail
        end

        # Chomp the string so that any trailing newlines are killed
        return real_guestpath.chomp
      end

      def mount_folder(name, guestpath, options)
        # Determine the permission string to attach to the mount command
        mount_options = "-o uid=`id -u #{options[:owner]}`,gid=`id -g #{options[:group]}`"
        mount_options += ",#{options[:extra]}" if options[:extra]

        attempts = 0
        while true
          success = true
          @vm.channel.sudo("mount -t vboxsf #{mount_options} #{name} #{guestpath}") do |type, data|
            success = false if type == :stderr && data =~ /No such device/i
          end

          break if success

          attempts += 1
          raise LinuxError, :mount_fail if attempts >= 10
          sleep 5
        end
      end
    end
  end
end
