module VagrantPlugins
  module GuestLinux
    module Cap
      class MountVirtualBoxSharedFolder
        def self.mount_virtualbox_shared_folder(machine, name, guestpath, options)
          expanded_guest_path = machine.guest.capability(
            :shell_expand_guest_path, guestpath)

          #check if mounts are already there
          checkresult = machine.communicate.sudo("cat /etc/mtab | grep '#{expanded_guest_path} '", error_check: false)

          if checkresult != 0

            mount_commands = []

            # First mount command uses getent to get the group
            mount_options = "uid=`id -u #{options[:owner]}`,gid=`getent group #{options[:group]} | cut -d: -f3`"
            mount_options += ",#{options[:mount_options].join(",")}" if options[:mount_options]
            mount_commands << "mount -t vboxsf -o #{mount_options} #{name} #{expanded_guest_path}"

            # Second mount command uses the old style `id -g`
            mount_options = "uid=`id -u #{options[:owner]}`,gid=`id -g #{options[:group]}`"
            mount_options += ",#{options[:mount_options].join(",")}" if options[:mount_options]
            mount_commands << "mount -t vboxsf -o #{mount_options} #{name} #{expanded_guest_path}"

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
                # add to fstab
                if success
                  machine.communicate.sudo("echo \"#{name} #{expanded_guest_path} vboxsf #{mount_options} 0 0\" >> /etc/fstab");
                end
                break if success
              end

              break if success

              attempts += 1
              if attempts > 10
                raise Vagrant::Errors::LinuxMountFailed,
                  command: mount_commands.join("\n")
              end

              sleep 2
            end

            # Chown the directory to the proper user
            chown_commands = []
            chown_commands << "chown `id -u #{options[:owner]}`:`getent group #{options[:group]} " +
              "| cut -d: -f3` #{expanded_guest_path}"
            chown_commands << "chown `id -u #{options[:owner]}`:`id -g #{options[:group]}` " +
              "#{expanded_guest_path}"

            exit_status = machine.communicate.sudo(chown_commands[0], error_check: false)
            return if exit_status == 0
            machine.communicate.sudo(chown_commands[1])
          end
        end
      end
    end
  end
end
