require "shellwords"
require_relative "../../../synced_folders/unix_mount_helpers"

module VagrantPlugins
  module GuestLinux
    module Cap
      class MountSMBSharedFolder

        extend SyncedFolder::UnixMountHelpers

        def self.mount_smb_shared_folder(machine, name, guestpath, options)
          expanded_guest_path = machine.guest.capability(
            :shell_expand_guest_path, guestpath)

          mount_device   = "//#{options[:smb_host]}/#{name}"

          mount_options = options.fetch(:mount_options, [])
          detected_ids = detect_owner_group_ids(machine, guestpath, mount_options, options)
          mount_uid = detected_ids[:uid]
          mount_gid = detected_ids[:gid]

          # If a domain is provided in the username, separate it
          username, domain = (options[:smb_username] || '').split('@', 2)
          smb_password = options[:smb_password]

          options[:mount_options] ||= []
          options[:mount_options] << "sec=ntlm"
          options[:mount_options] << "credentials=/etc/smb_creds_#{name}"

          mount_options = "-o uid=#{mount_uid},gid=#{mount_gid}"
          mount_options += ",#{Array(options[:mount_options]).join(",")}" if options[:mount_options]
          mount_command = "mount -t cifs #{mount_options} #{mount_device} #{expanded_guest_path}"

          # Create the guest path if it doesn't exist
          machine.communicate.sudo("mkdir -p #{expanded_guest_path}")

          # Write the credentials file
          machine.communicate.sudo(<<-SCRIPT)
cat <<"EOF" >/etc/smb_creds_#{name}
username=#{username}
password=#{smb_password}
#{domain ? "domain=#{domain}" : ""}
EOF
chmod 0600 /etc/smb_creds_#{name}
SCRIPT

          # Attempt to mount the folder. We retry here a few times because
          # it can fail early on.

          retryable(on: Vagrant::Errors::LinuxMountFailed, tries: 10, sleep: 2) do
            no_such_device = false
            stderr = ""
            status = machine.communicate.sudo(mount_command, error_check: false) do |type, data|
              if type == :stderr
                no_such_device = true if data =~ /No such device/i
                stderr += data.to_s
              end
            end
            if status != 0 || no_such_device
              clean_command = mount_command.gsub(smb_password, "PASSWORDHIDDEN")
              raise Vagrant::Errors::LinuxMountFailed,
                command: clean_command,
                output: stderr
            end
          end

          emit_upstart_notification(machine, expanded_guest_path)
        end
      end
    end
  end
end
