module VagrantPlugins
  module GuestLinux
    module Cap
      class MountVirtualBoxSharedFolder
        def self.mount_virtualbox_shared_folder(machine, name, guestpath, options)
          expanded_guest_path = machine.guest.capability(
            :shell_expand_guest_path, guestpath)

          # Determine the permission string to attach to the mount command
          mount_options = "-o uid=`id -u #{options[:owner]}`,gid=`id -g #{options[:group]}`"
          mount_options += ",#{options[:extra]}" if options[:extra]
          mount_command = "mount -t vboxsf #{mount_options} #{name} #{expanded_guest_path}"

          # Create the guest path if it doesn't exist
          machine.communicate.sudo("mkdir -p #{expanded_guest_path}")

          # Attempt to mount the folder. We retry here a few times because
          # it can fail early on.
          attempts = 0
          while true
            success = true
            machine.communicate.sudo(mount_command) do |type, data|
              success = false if type == :stderr && data =~ /No such device/i
            end

            break if success

            attempts += 1
            raise Vagrant::Errors::LinuxMountFailed, :command => mount_command
            sleep 2
          end

          # Chown the directory to the proper user
          machine.communicate.sudo(
            "chown `id -u #{options[:owner]}`:`id -g #{options[:group]}` #{expanded_guest_path}")
        end
      end
    end
  end
end
