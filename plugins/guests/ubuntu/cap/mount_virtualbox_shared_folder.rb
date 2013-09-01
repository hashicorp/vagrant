require Vagrant.source_root.join("plugins/guests/linux/cap/mount_virtualbox_shared_folder")

module VagrantPlugins
  module GuestUbuntu
    module Cap
      class MountVirtualBoxSharedFolder < GuestLinux::Cap::MountVirtualBoxSharedFolder
        def self.mount_virtualbox_shared_folder(machine, name, guestpath, options)
          super
          machine.communicate.sudo("[ -x /sbin/initctl ] && /sbin/initctl emit vagrant-mounted MOUNTPOINT=#{guestpath}")
        end
      end
    end
  end
end
