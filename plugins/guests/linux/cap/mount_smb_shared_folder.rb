require "fileutils"
require "shellwords"
require_relative "../../../synced_folders/unix_mount_helpers"

module VagrantPlugins
  module GuestLinux
    module Cap
      class MountSMBSharedFolder

        extend SyncedFolder::UnixMountHelpers

        # Mounts and SMB folder on linux guest
        #
        # @param [Machine] machine
        # @param [String] name of mount
        # @param [String] path of mount on guest
        # @param [Hash] hash of mount options 
        def self.mount_smb_shared_folder(machine, name, guestpath, options)
          expanded_guest_path = machine.guest.capability(
            :shell_expand_guest_path, guestpath)
          options[:smb_id] ||= name

          mount_device = options[:plugin].capability(:mount_name, options)
          mount_options, _, _ = options[:plugin].capability(
            :mount_options, name, expanded_guest_path, options)
          mount_type = options[:plugin].capability(:mount_type)
          # If a domain is provided in the username, separate it
          username, domain = (options[:smb_username] || '').split('@', 2)
          smb_password = options[:smb_password]
          # Ensure password is scrubbed
          Vagrant::Util::CredentialScrubber.sensitive(smb_password)
        
          if mount_options.include?("mfsymlinks")
            display_mfsymlinks_warning(machine.env)
          end
          
          mount_command = "mount -t #{mount_type} -o #{mount_options} #{mount_device} #{expanded_guest_path}"

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
            if !machine.config.vm.allow_fstab_modification
              machine.communicate.sudo("rm /etc/smb_creds_#{name}")
            end
          end

          emit_upstart_notification(machine, expanded_guest_path)
        end

        def self.display_mfsymlinks_warning(env)
          d_file = env.data_dir.join("mfsymlinks_warning")
          if !d_file.exist?
            FileUtils.touch(d_file.to_path)
            env.ui.warn(I18n.t("vagrant.actions.vm.smb.mfsymlink_warning"))
          end
        end
      end
    end
  end
end
