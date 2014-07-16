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

          smb_password = Shellwords.shellescape(options[:smb_password])

          options[:mount_options] ||= []
          options[:mount_options] << "username=#{options[:smb_username]}"
          options[:mount_options] << "pass=#{smb_password}"

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

          # Attempt to mount the folder. We retry here a few times because
          # it can fail early on.
          attempts = 0
          while true
            success = true

            mount_commands.each do |command|
              no_such_device = false
              status = machine.communicate.sudo(command, error_check: false) do |type, data|
                no_such_device = true if type == :stderr && data =~ /No such device/i
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
                command: command
            end

            sleep 2
          end

          # Emit an upstart event if we can
          if machine.communicate.test("test -x /sbin/initctl")
            machine.communicate.sudo(
              "/sbin/initctl emit --no-wait vagrant-mounted MOUNTPOINT=#{expanded_guest_path}")
          end
        end
      end
    end
  end
end
