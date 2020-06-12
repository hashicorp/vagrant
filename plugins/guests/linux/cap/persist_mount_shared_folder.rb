require "vagrant/util"

require_relative "../../../synced_folders/unix_mount_helpers"

module VagrantPlugins
  module GuestLinux
    module Cap
      class PersistMountSharedFolder
        extend SyncedFolder::UnixMountHelpers

        # Inserts fstab entry for a set of synced folders. Will fully replace
        # the currently managed group of Vagrant managed entries. Note, passing
        # empty list of folders will just remove entries      
        # 
        # @param [Machine] machine The machine to run the action on
        # @param [Map<String, Map>] A map of folders to add to fstab
        # @param [String] mount type, ex. vboxfs, cifs, etc
        def self.persist_mount_shared_folder(machine, fstab_folders, mount_type)
          if fstab_folders.empty?
            self.remove_vagrant_managed_fstab(machine)
            return
          end
          export_folders = fstab_folders.map do |name, data|
            guest_path = Shellwords.escape(data[:guestpath])
            mount_options, mount_uid, mount_gid  =  mount_options(machine, name, guest_path, data)
            mount_options = "#{mount_options},nofail"
            {
              name: name,
              mount_point: guest_path,
              mount_type: mount_type,
              mount_options: mount_options,
            }
          end

          fstab_entry = Vagrant::Util::TemplateRenderer.render('guests/linux/etc_fstab', folders: export_folders)
          self.remove_vagrant_managed_fstab(machine)
          machine.communicate.sudo("echo '#{fstab_entry}' >> /etc/fstab")
        end

        private

        def self.remove_vagrant_managed_fstab(machine)
          machine.communicate.sudo("sed -i '/\#VAGRANT-BEGIN/,/\#VAGRANT-END/d' /etc/fstab")
        end
      end
    end
  end
end