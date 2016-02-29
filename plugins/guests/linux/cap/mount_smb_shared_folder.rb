require "shellwords"

module VagrantPlugins
  module GuestLinux
    module Cap
      class MountSMBSharedFolder
        def self.mount_smb_shared_folder(machine, name, guestpath, options)
          expanded_guest_path = machine.guest.capability(
            :shell_expand_guest_path, guestpath)

          mount_commands = []
          mount_device   = "//#{options[:smb_host]}/#{name}"

          if options[:owner].is_a? Integer
            mount_uid = options[:owner]
          else
            mount_uid = "`id -u #{options[:owner]}`"
          end

          if options[:group].is_a? Integer
            mount_gid = options[:group]
            mount_gid_old = options[:group]
          else
            mount_gid = "`getent group #{options[:group]} | cut -d: -f3`"
            mount_gid_old = "`id -g #{options[:group]}`"
          end

          # If a domain is provided in the username, separate it
          username, domain = (options[:smb_username] || '').split('@', 2)
          smb_password = options[:smb_password]

          options[:mount_options] ||= []
          options[:mount_options] << "sec=ntlm"
          options[:mount_options] << "credentials=/etc/smb_creds_#{name}"

          # First mount command uses getent to get the group
          mount_options = "-o uid=#{mount_uid},gid=#{mount_gid}"
          mount_options += ",#{options[:mount_options].join(",")}" if options[:mount_options]
          mount_commands << "mount -t cifs #{mount_options} #{mount_device} #{expanded_guest_path}"

          # Second mount command uses the old style `id -g`
          mount_options = "-o uid=#{mount_uid},gid=#{mount_gid_old}"
          mount_options += ",#{options[:mount_options].join(",")}" if options[:mount_options]
          mount_commands << "mount -t cifs #{mount_options} #{mount_device} #{expanded_guest_path}"

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
          attempts = 0
          while true
            success = true

            stderr = ""
            mount_commands.each do |command|
              no_such_device = false
              stderr = ""
              status = machine.communicate.sudo(command, error_check: false) do |type, data|
                if type == :stderr
                  no_such_device = true if data =~ /No such device/i
                  stderr += data.to_s
                end
              end

              success = status == 0 && !no_such_device
              break if success
            end

            break if success

            attempts += 1
            if attempts > 10
              command = mount_commands.join("\n")
              command.gsub!(smb_password, "PASSWORDHIDDEN")

              raise Vagrant::Errors::LinuxMountFailed,
                command: command,
                output: stderr
            end

            sleep 2
          end

          # Emit an upstart event if we can
          machine.communicate.sudo <<-SCRIPT
if command -v /sbin/init &>/dev/null && /sbin/init --version | grep upstart &>/dev/null; then
  /sbin/initctl emit --no-wait vagrant-mounted MOUNTPOINT='#{expanded_guest_path}'
fi
SCRIPT
        end
      end
    end
  end
end
