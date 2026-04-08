# Copyright IBM Corp. 2010, 2025
# SPDX-License-Identifier: BUSL-1.1

require "vagrant/util"
require "vagrant/util/guest_inspection"

require_relative "../../../synced_folders/unix_mount_helpers"

module VagrantPlugins
  module GuestLinux
    module Cap
      class PersistMountSharedFolder
        extend SyncedFolder::UnixMountHelpers
        extend Vagrant::Util::GuestInspection::Linux

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
            changed = remove_vagrant_managed_fstab(machine)
            systemd_daemon_reload(machine) if changed
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
                  name = data[:plugin].capability(:mount_name, name, data)
                end
              else
                next
              end

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
          systemd_daemon_reload(machine)
        end

        private

        def self.systemd_daemon_reload(machine)
          if systemd?(machine.communicate)
            machine.communicate.sudo("systemctl daemon-reload")
          end
        end

        def self.fstab_exists?(machine)
          machine.communicate.test("test -f /etc/fstab")
        end

        def self.contains_vagrant_data?(machine)
          machine.communicate.test("grep '#VAGRANT-BEGIN' /etc/fstab")
        end

        def self.remove_vagrant_managed_fstab(machine)
          fstab_is_modified = false

          if fstab_exists?(machine)
            if contains_vagrant_data?(machine)
                machine.communicate.sudo("sed -i '/\#VAGRANT-BEGIN/,/\#VAGRANT-END/d' /etc/fstab")
                fstab_is_modified = true
            else
                @@logger.info("no vagrant data in fstab file, carrying on")
            end
          else
            @@logger.info("no fstab file found, carrying on")
          end

          fstab_is_modified
        end
      end
    end
  end
end
