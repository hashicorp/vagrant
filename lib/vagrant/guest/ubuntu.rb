require 'vagrant/guest/debian'

module Vagrant
  module Guest
    class Ubuntu < Debian
      def mount_shared_folder(name, guestpath, options)
        # Mount it like normal
        super

        # Emit an upstart event if upstart is available
        vm.channel.sudo("[ -x /sbin/initctl ] && /sbin/initctl emit vagrant-mounted MOUNTPOINT=#{guestpath}")
      end

      def mount_nfs(ip, folders)
        # Mount it like normal
        super

        folders.each do |name, opts|
          # Expand the guestpath, so we can handle things like "~/vagrant"
          real_guestpath = expanded_guest_path(opts[:guestpath])

          # Emit an upstart event if upstart is available
          vm.channel.sudo("[ -x /sbin/initctl ] && /sbin/initctl emit vagrant-mounted MOUNTPOINT=#{real_guestpath}")
        end
      end

      def change_host_name(name)
        if !vm.channel.test("sudo hostname | grep '#{name}'")
          vm.channel.sudo("sed -i 's/.*$/#{name}/' /etc/hostname")
          vm.channel.sudo("sed -i 's@^\\(127[.]0[.]1[.]1[[:space:]]\\+\\)@\\1#{name} #{name.split('.')[0]} @' /etc/hosts")
          vm.channel.sudo("service hostname start")
        end
      end
    end
  end
end
