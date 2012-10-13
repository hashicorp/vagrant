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

      def change_host_name(name)
        if !vm.channel.test("sudo hostname | grep '^#{name}$'")
          vm.channel.sudo("sed -i 's/.*$/#{name}/' /etc/hostname")
          vm.channel.sudo("sed -i 's@^\\(127[.]0[.]1[.]1[[:space:]]\\+\\)@\\1#{name} #{name.split('.')[0]} @' /etc/hosts")
          vm.channel.sudo("service hostname start")
        end
      end
    end
  end
end
