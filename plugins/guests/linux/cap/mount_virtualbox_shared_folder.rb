module VagrantPlugins
  module GuestLinux
    module Cap
      class MountVirtualBoxSharedFolder
        def self.mount_virtualbox_shared_folder(machine, name, guestpath, options)
          expanded_guest_path = machine.guest.capability(
            :shell_expand_guest_path, guestpath)

          mount_commands = []

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

          # First mount command uses getent to get the group
          mount_options = "-o uid=#{mount_uid},gid=#{mount_gid}"
          mount_options += ",#{options[:mount_options].join(",")}" if options[:mount_options]
          mount_commands << "mount -t vboxsf #{mount_options} #{name} #{expanded_guest_path}"

          # Second mount command uses the old style `id -g`
          mount_options = "-o uid=#{mount_uid},gid=#{mount_gid_old}"
          mount_options += ",#{options[:mount_options].join(",")}" if options[:mount_options]
          mount_commands << "mount -t vboxsf #{mount_options} #{name} #{expanded_guest_path}"

          # Create the guest path if it doesn't exist
          machine.communicate.sudo("mkdir -p #{expanded_guest_path}")

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
              raise Vagrant::Errors::LinuxMountFailed,
                command: mount_commands.join("\n"),
                output: stderr
            end

            sleep(2*attempts)
          end

          # Chown the directory to the proper user. We skip this if the
          # mount options contained a readonly flag, because it won't work.
          if !options[:mount_options] || !options[:mount_options].include?("ro")
            chown_commands = []
            chown_commands << "chown #{mount_uid}:#{mount_gid} #{expanded_guest_path}"
            chown_commands << "chown #{mount_uid}:#{mount_gid_old} #{expanded_guest_path}"

            exit_status = machine.communicate.sudo(chown_commands[0], error_check: false)
            machine.communicate.sudo(chown_commands[1]) if exit_status != 0
          end

          # Emit an upstart event if we can
          if machine.communicate.test("test -x /sbin/initctl && test 'upstart' = $(basename $(sudo readlink /proc/1/exe))")
            machine.communicate.sudo(
              "/sbin/initctl emit --no-wait vagrant-mounted MOUNTPOINT=#{expanded_guest_path}")
          end
        end

        def self.unmount_virtualbox_shared_folder(machine, guestpath, options)
          result = machine.communicate.sudo(
            "umount #{guestpath}", error_check: false)
          if result == 0
            machine.communicate.sudo("rmdir #{guestpath}", error_check: false)
          end
        end
      end
    end
  end
end
