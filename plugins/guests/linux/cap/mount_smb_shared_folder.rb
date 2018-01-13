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
          # Ensure password is scrubbed
          Vagrant::Util::CredentialScrubber.sensitive(smb_password)

          mnt_opts = []
          if machine.env.host.capability?(:smb_mount_options)
            mnt_opts += machine.env.host.capability(:smb_mount_options)
          else
            mnt_opts << "sec=ntlmssp"
          end
          mnt_opts << "credentials=/etc/smb_creds_#{name}"
          mnt_opts << "uid=#{mount_uid}"
          mnt_opts << "gid=#{mount_gid}"

          mnt_opts = merge_mount_options(mnt_opts, options[:mount_options] || [])

          mount_options = "-o #{mnt_opts.join(",")}"
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
          begin
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
                raise Vagrant::Errors::LinuxMountFailed,
                  command: mount_command,
                  output: stderr
              end
            end
          ensure
            # Always remove credentials file after mounting attempts
            # have been completed
            machine.communicate.sudo("rm /etc/smb_creds_#{name}")
          end

          emit_upstart_notification(machine, expanded_guest_path)
        end

        def self.merge_mount_options(base, overrides)
          base = base.join(",").split(",")
          overrides = overrides.join(",").split(",")
          b_kv = Hash[base.map{|item| item.split("=", 2) }]
          o_kv = Hash[overrides.map{|item| item.split("=", 2) }]
          merged = {}.tap do |opts|
            (b_kv.keys + o_kv.keys).uniq.each do |key|
              opts[key] = o_kv.fetch(key, b_kv[key])
            end
          end
          merged.map do |key, value|
            [key, value].compact.join("=")
          end
        end
      end
    end
  end
end
