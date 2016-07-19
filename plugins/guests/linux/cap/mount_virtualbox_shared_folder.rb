require "shellwords"

require "vagrant/util/retryable"

module VagrantPlugins
  module GuestLinux
    module Cap
      class MountVirtualBoxSharedFolder
        extend Vagrant::Util::Retryable

        def self.mount_virtualbox_shared_folder(machine, name, guestpath, options)
          guest_path = Shellwords.escape(guestpath)

          mount_commands = ["set -e"]

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
          mount_commands << "mount -t vboxsf #{mount_options} #{name} #{guest_path}"

          # Second mount command uses the old style `id -g`
          mount_options = "-o uid=#{mount_uid},gid=#{mount_gid_old}"
          mount_options += ",#{options[:mount_options].join(",")}" if options[:mount_options]
          mount_commands << "mount -t vboxsf #{mount_options} #{name} #{guest_path}"

          # Create the guest path if it doesn't exist
          machine.communicate.sudo("mkdir -p #{guest_path}")

          # Attempt to mount the folder. We retry here a few times because
          # it can fail early on.
          command = mount_commands.join("\n")
          stderr = ""
          retryable(on: Vagrant::Errors::VirtualBoxMountFailed, tries: 3, sleep: 5) do
            machine.communicate.sudo(command,
              error_class: Vagrant::Errors::VirtualBoxMountFailed,
              error_key: :virtualbox_mount_failed,
              command: command,
              output: stderr,
            ) { |type, data| stderr = data if type == :stderr }
          end

          # Chown the directory to the proper user. We skip this if the
          # mount options contained a readonly flag, because it won't work.
          if !options[:mount_options] || !options[:mount_options].include?("ro")
            chown_commands = []
            chown_commands << "chown #{mount_uid}:#{mount_gid} #{guest_path}"
            chown_commands << "chown #{mount_uid}:#{mount_gid_old} #{guest_path}"

            exit_status = machine.communicate.sudo(chown_commands[0], error_check: false)
            machine.communicate.sudo(chown_commands[1]) if exit_status != 0
          end

          # Emit an upstart event if we can
          machine.communicate.sudo <<-EOH.gsub(/^ {12}/, "")
            if command -v /sbin/init && /sbin/init --version | grep upstart; then
              /sbin/initctl emit --no-wait vagrant-mounted MOUNTPOINT=#{guest_path}
            fi
          EOH
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
