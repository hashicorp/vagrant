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

      def change_host_name(name)
        vm.communicate.tap do |comm|
          if !comm.test("sudo hostname | grep '#{name}'")
            comm.sudo("sed -i 's/.*$/#{name}/' /etc/hostname")
            comm.sudo("sed -i 's@^\\(127[.]0[.]1[.]1[[:space:]]\\+\\)@\\1#{name} #{name.split('.')[0]} @' /etc/hosts")
            comm.sudo("service hostname start")
            comm.sudo("hostname --fqdn > /etc/mailname")
          end
        end
      end
    end
  end
end
