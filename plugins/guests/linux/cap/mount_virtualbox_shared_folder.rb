require "vagrant/util"

require_relative "../../../synced_folders/unix_mount_helpers"

module VagrantPlugins
  module GuestLinux
    module Cap
      class MountVirtualBoxSharedFolder
        extend SyncedFolder::UnixMountHelpers

        VB_MOUNT_TYPE = "vboxsf".freeze

        def self.mount_virtualbox_shared_folder(machine, name, guestpath, options)
          guest_path = Shellwords.escape(guestpath)

          @@logger.debug("Mounting #{name} (#{options[:hostpath]} to #{guestpath})")

          builtin_mount_type = "-cit #{VB_MOUNT_TYPE}"
          addon_mount_type = "-t #{VB_MOUNT_TYPE}"

          mount_options, mount_uid, mount_gid = self.mount_options(machine, name, guest_path, options)
          mount_command = "mount #{addon_mount_type} -o #{mount_options} #{name} #{guest_path}"

          # Create the guest path if it doesn't exist
          machine.communicate.sudo("mkdir -p #{guest_path}")

          stderr = ""
          result = machine.communicate.sudo(mount_command, error_check: false) do |type, data|
            stderr << data if type == :stderr
          end

          if result != 0
            if stderr.include?("-cit")
              @@logger.info("Detected builtin vboxsf module, modifying mount command")
              mount_command.sub!(addon_mount_type, builtin_mount_type)
            end

            # Attempt to mount the folder. We retry here a few times because
            # it can fail early on.
            stderr = ""
            retryable(on: Vagrant::Errors::VirtualBoxMountFailed, tries: 3, sleep: 5) do
              machine.communicate.sudo(mount_command,
                error_class: Vagrant::Errors::VirtualBoxMountFailed,
                error_key: :virtualbox_mount_failed,
                command: mount_command,
                output: stderr,
              ) { |type, data| stderr = data if type == :stderr }
            end
          end

          # Chown the directory to the proper user. We skip this if the
          # mount options contained a readonly flag, because it won't work.
          if !options[:mount_options] || !options[:mount_options].include?("ro")
            chown_command = "chown #{mount_uid}:#{mount_gid} #{guest_path}"
            machine.communicate.sudo(chown_command)
          end

          emit_upstart_notification(machine, guest_path)
        end

        def self.persist_mount_virtualbox_shared_folder(machine, fstab_folders)
          export_folders = fstab_folders.map do |name, data|
            guest_path = Shellwords.escape(data[:guestpath])
            mount_options, mount_uid, mount_gid  =  self.mount_options(machine, name, guest_path, data)
            mount_options = "#{mount_options},nofail"
            {
              name: name,
              mount_point: guest_path,
              mount_type: VB_MOUNT_TYPE,
              mount_options: mount_options,
            }
          end

          fstab_entry = Vagrant::Util::TemplateRenderer.render('guests/linux/etc_fstab', folders: export_folders)
          # Replace existing vagrant managed fstab entry
          machine.communicate.sudo("sed -i '/\#VAGRANT-BEGIN/,/\#VAGRANT-END/d' /etc/fstab")
          machine.communicate.sudo("echo '#{fstab_entry}' >> /etc/fstab")

          fstab_valid = machine.communicate.test("mount -a", sudo: true)
          if !fstab_valid 
            machine.communicate.sudo("sed -i '/\#VAGRANT-BEGIN/,/\#VAGRANT-END/d' /etc/fstab")
            @@logger.info("Generated fstab not valid. Backing out change to /etc/fstab")
            @@logger.info("Generted fstab:\n#{fstab_entry}")
          end
        end

        def self.unmount_virtualbox_shared_folder(machine, guestpath, options)
          guest_path = Shellwords.escape(guestpath)

          result = machine.communicate.sudo("umount #{guest_path}", error_check: false)
          if result == 0
            machine.communicate.sudo("rmdir #{guest_path}", error_check: false)
          end
        end

        private

        def self.mount_options(machine, name, guest_path, options)
          mount_options = options.fetch(:mount_options, [])
          detected_ids = detect_owner_group_ids(machine, guest_path, mount_options, options)
          mount_uid = detected_ids[:uid]
          mount_gid = detected_ids[:gid]

          mount_options << "uid=#{mount_uid}"
          mount_options << "gid=#{mount_gid}"
          mount_options = mount_options.join(',')
          return mount_options, mount_uid, mount_gid
        end
      end
    end
  end
end
