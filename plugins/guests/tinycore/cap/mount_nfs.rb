require_relative "../../../synced_folders/unix_mount_helpers"

module VagrantPlugins
  module GuestTinyCore
    module Cap
      class MountNFS
        extend SyncedFolder::UnixMountHelpers

        def self.mount_nfs_folder(machine, ip, folders)
          folders.each do |name, opts|
            # Expand the guest path so we can handle things like "~/vagrant"
            expanded_guest_path = machine.guest.capability(
              :shell_expand_guest_path, opts[:guestpath])

            # Do the actual creating and mounting
            machine.communicate.sudo("mkdir -p #{expanded_guest_path}")

            # Mount
            hostpath = opts[:hostpath].dup
            hostpath.gsub!("'", "'\\\\''")

            # Figure out any options
            mount_opts = ["vers=#{opts[:nfs_version]}"]
            mount_opts << "udp" if opts[:nfs_udp]
            if opts[:mount_options]
              mount_opts = opts[:mount_options].dup
            end

            mount_command = "mount.nfs -o '#{mount_opts.join(",")}' #{ip}:'#{hostpath}' #{expanded_guest_path}"
            retryable(on: Vagrant::Errors::NFSMountFailed, tries: 8, sleep: 3) do
              machine.communicate.sudo(mount_command,
                                       error_class: Vagrant::Errors::NFSMountFailed)
            end

            emit_upstart_notification(machine, expanded_guest_path)
          end
        end
      end
    end
  end
end
