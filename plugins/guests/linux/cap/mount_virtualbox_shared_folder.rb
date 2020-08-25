require_relative "../../../synced_folders/unix_mount_helpers"

module VagrantPlugins
  module GuestLinux
    module Cap
      class MountVirtualBoxSharedFolder
        extend SyncedFolder::UnixMountHelpers

        # Mounts and virtualbox folder on linux guest
        #
        # @param [Machine] machine
        # @param [String] name of mount
        # @param [String] path of mount on guest
        # @param [Hash] hash of mount options 
        def self.mount_virtualbox_shared_folder(machine, name, guestpath, options)
          guest_path = Shellwords.escape(guestpath)
          mount_type = options[:plugin].capability(:mount_type)

          @@logger.debug("Mounting #{name} (#{options[:hostpath]} to #{guestpath})")

          builtin_mount_type = "-cit #{mount_type}"
          addon_mount_type = "-t #{mount_type}"

          mount_options, mount_uid, mount_gid = options[:plugin].capability(:mount_options, name, guest_path, options)
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

        def self.unmount_virtualbox_shared_folder(machine, guestpath, options)
          guest_path = Shellwords.escape(guestpath)

          result = machine.communicate.sudo("umount #{guest_path}", error_check: false)
          if result == 0
            machine.communicate.sudo("rmdir #{guest_path}", error_check: false)
          end
        end
      end
    end
  end
end
