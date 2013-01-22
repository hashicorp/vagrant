require 'log4r'

require "vagrant"

module VagrantPlugins
  module GuestLinux
    class Guest < Vagrant.plugin("2", :guest)
      class LinuxError < Vagrant::Errors::VagrantError
        error_namespace("vagrant.guest.linux")
      end

      def initialize(*args)
        super

        @logger = Log4r::Logger.new("vagrant::guest::linux")
      end

      def distro_dispatch
        @vm.communicate.tap do |comm|
          if comm.test("cat /etc/debian_version")
            return :debian if comm.test("cat /proc/version | grep 'Debian'")
            return :ubuntu if comm.test("cat /proc/version | grep 'Ubuntu'")
          end

          return :gentoo if comm.test("cat /etc/gentoo-release")
          return :fedora if comm.test("grep 'Fedora release 1[678]' /etc/redhat-release")
          return :redhat if comm.test("cat /etc/redhat-release")
          return :suse if comm.test("cat /etc/SuSE-release")
          return :arch if comm.test("cat /etc/arch-release")
        end

        # Can't detect the distro, assume vanilla linux
        nil
      end

      def halt
        @vm.communicate.sudo("shutdown -h now")
      end

      def mount_shared_folder(name, guestpath, options)
        real_guestpath = expanded_guest_path(guestpath)
        @logger.debug("Shell expanded guest path: #{real_guestpath}")

        @vm.communicate.sudo("mkdir -p #{real_guestpath}")
        mount_folder(name, real_guestpath, options)
        @vm.communicate.sudo("chown `id -u #{options[:owner]}`:`id -g #{options[:group]}` #{real_guestpath}")
      end

      def mount_nfs(ip, folders)
        # TODO: Maybe check for nfs support on the guest, since its often
        # not installed by default
        folders.each do |name, opts|
          # Expand the guestpath, so we can handle things like "~/vagrant"
          real_guestpath = expanded_guest_path(opts[:guestpath])

          # Do the actual creating and mounting
          @vm.communicate.sudo("mkdir -p #{real_guestpath}")
          @vm.communicate.sudo("mount -o vers=#{opts[:nfs_version]} #{ip}:'#{opts[:hostpath]}' #{real_guestpath}",
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
        @vm.communicate.execute("printf #{guestpath}") do |type, data|
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
          @vm.communicate.sudo("mount -t vboxsf #{mount_options} #{name} #{guestpath}") do |type, data|
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
