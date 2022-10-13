require "vagrant/util"

require_relative "../../../synced_folders/unix_mount_helpers"

module VagrantPlugins
  module GuestLinux
    module Cap
      class PersistMountSharedFolder
        extend SyncedFolder::UnixMountHelpers

        @@logger = Log4r::Logger.new("vagrant::guest::linux::persist_mount_shared_folders")

        # Inserts fstab entry for a set of synced folders. Will fully replace
        # the currently managed group of Vagrant managed entries. Note, passing
        # empty list of folders will just remove entries
        #
        # @param [Machine] machine The machine to run the action on
        # @param [Map<String, Map>] A map of folders to add to fstab
        def self.persist_mount_shared_folder(machine, folders)
          if folders.nil?
            @@logger.info("clearing /etc/fstab")
            self.remove_vagrant_managed_fstab(machine)
            return
          end

          ssh_info = machine.ssh_info
          export_folders = folders.map { |type, folder|
            folder.map { |name, data|
              if data[:plugin].capability?(:mount_type)
                guest_path = Shellwords.escape(data[:guestpath])
                data[:owner] ||= ssh_info[:username]
                data[:group] ||= ssh_info[:username]
                mount_type = data[:plugin].capability(:mount_type)
                mount_options, _, _ = data[:plugin].capability(
                  :mount_options, name, guest_path, data)
                if data[:plugin].capability?(:mount_name)
                  name = data[:plugin].capability(:mount_name, data)
                end
              else
                next
              end

              mount_options = "#{mount_options},nofail"
              {
                name: name,
                mount_point: guest_path,
                mount_type: mount_type,
                mount_options: mount_options,
              }
            }
          }.flatten.compact


          fstab_entry = Vagrant::Util::TemplateRenderer.render('guests/linux/etc_fstab', folders: export_folders)
          self.remove_vagrant_managed_fstab(machine)
          machine.communicate.sudo("echo '#{fstab_entry}' >> /etc/fstab")
        end

        private

        def self.fstab_exists?(machine)
          machine.communicate.test("test -f /etc/fstab")
        end

        def self.remove_vagrant_managed_fstab(machine)
          if fstab_exists?(machine)
            machine.communicate.sudo("sed -i '/\#VAGRANT-BEGIN/,/\#VAGRANT-END/d' /etc/fstab")
          else
            @@logger.info("no fstab file found, carrying on")
          end
        end
      end
    end
  end
end
