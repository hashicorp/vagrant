require 'log4r'

require "vagrant"
require "vagrant/util/retryable"

module VagrantPlugins
  module GuestLinux
    class Guest < Vagrant.plugin("2", :guest)
      include Vagrant::Util::Retryable

      def detect?(machine)
        # TODO: Linux detection
        false
      end

      def halt
        begin
          @vm.communicate.sudo("shutdown -h now")
        rescue IOError
          # Do nothing, because it probably means the machine shut down
          # and SSH connection was lost.
        end
      end

      def mount_nfs(ip, folders)
        # TODO: Maybe check for nfs support on the guest, since its often
        # not installed by default
        folders.each do |name, opts|
          # Expand the guestpath, so we can handle things like "~/vagrant"
          real_guestpath = expanded_guest_path(opts[:guestpath])

          # Do the actual creating and mounting
          @vm.communicate.sudo("mkdir -p #{real_guestpath}")

          retryable(:on => LinuxError, :tries => 5, :sleep => 2) do
            @vm.communicate.sudo("mount -o vers=#{opts[:nfs_version]} #{ip}:'#{opts[:hostpath]}' #{real_guestpath}",
                                 :error_class => LinuxError,
                                   :error_key => :mount_nfs_fail)
          end
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
    end
  end
end
