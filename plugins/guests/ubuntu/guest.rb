require "vagrant"

require Vagrant.source_root.join("plugins/guests/debian/guest")

module VagrantPlugins
  module GuestUbuntu
    class Guest < VagrantPlugins::GuestDebian::Guest
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

      def change_host_name(name)
        vm.communicate.tap do |comm|
          if !comm.test("sudo hostname | grep '^#{name}$'")
            comm.sudo("sed -i 's/.*$/#{name}/' /etc/hostname")
            comm.sudo("sed -i 's@^\\(127[.]0[.]1[.]1[[:space:]]\\+\\)@\\1#{name} #{name.split('.')[0]} @' /etc/hosts")
            if comm.test("[ `lsb_release -c -s` = hardy ]")
                # hostname.sh returns 1, so I grep for the right name in /etc/hostname just to have a 0 exitcode
                comm.sudo("/etc/init.d/hostname.sh start; grep '#{name}' /etc/hostname")
            else
                comm.sudo("service hostname start")
            end
            comm.sudo("hostname --fqdn > /etc/mailname")
          end
        end
      end
    end
  end
end
