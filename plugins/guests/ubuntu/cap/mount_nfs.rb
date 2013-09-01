require Vagrant.source_root.join("plugins/guests/linux/cap/mount_nfs")

module VagrantPlugins
  module GuestUbuntu
    module Cap
      class MountNFS < GuestLinux::Cap::MountNFS
        def self.mount_nfs_folder(machine, ip, folders)
          super

          # Emit an upstart events if upstart is available
          folders.each do |name, opts|
            real_guestpath =  machine.guest.capability(:shell_expand_guest_path, opts[:guestpath])
            machine.communicate.sudo("[ -x /sbin/initctl ] && /sbin/initctl emit vagrant-mounted MOUNTPOINT=#{real_guestpath}")
          end
        end
      end
    end
  end
end
