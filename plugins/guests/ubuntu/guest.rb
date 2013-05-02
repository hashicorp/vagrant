require "vagrant"

require Vagrant.source_root.join("plugins/guests/debian/guest")

module VagrantPlugins
  module GuestUbuntu
    class Guest < VagrantPlugins::GuestDebian::Guest
      def detect?(machine)
        machine.communicate.test("cat /etc/issue | grep 'Ubuntu'")
      end

      def mount_shared_folder(name, guestpath, options)
        # Mount it like normal
        super

        # Emit an upstart event if upstart is available
        vm.communicate.sudo("[ -x /sbin/initctl ] && /sbin/initctl emit vagrant-mounted MOUNTPOINT=#{guestpath}")
      end

      def mount_nfs(ip, folders)
        # Mount it like normal
        super

        # Emit an upstart events if upstart is available
        folders.each do |name, opts|
          real_guestpath = expanded_guest_path(opts[:guestpath])
          vm.communicate.sudo("[ -x /sbin/initctl ] && /sbin/initctl emit vagrant-mounted MOUNTPOINT=#{real_guestpath}")
        end
      end
    end
  end
end
