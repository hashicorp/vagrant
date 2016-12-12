require "shellwords"

require "vagrant/util/retryable"

module VagrantPlugins
  module GuestLinux
    module Cap
      class MountVirtualBoxSharedFolder
        @@logger = Log4r::Logger.new("vagrant::guest::linux::mount_virtualbox_shared_folder")

        extend Vagrant::Util::Retryable

        def self.mount_virtualbox_shared_folder(machine, name, guestpath, options)
          guest_path = Shellwords.escape(guestpath)

          @@logger.debug("Mounting #{name} (#{options[:hostpath]} to #{guestpath})")

          if options[:owner].to_i.to_s == options[:owner].to_s
            mount_uid = options[:owner]
            @@logger.debug("Owner user ID (provided): #{mount_uid}")
          else
            output = {stdout: '', stderr: ''}
            uid_command = "id -u #{options[:owner]}"
            machine.communicate.execute(uid_command,
              error_class: Vagrant::Errors::VirtualBoxMountFailed,
              error_key: :virtualbox_mount_failed,
              command: uid_command,
              output: output[:stderr]
            ) { |type, data| output[type] << data if output[type] }
            mount_uid = output[:stdout].chomp
            @@logger.debug("Owner user ID (lookup): #{options[:owner]} -> #{mount_uid}")
          end

          if options[:group].to_i.to_s == options[:group].to_s
            mount_gid = options[:group]
            @@logger.debug("Owner group ID (provided): #{mount_gid}")
          else
            begin
              output = {stdout: '', stderr: ''}
              gid_command = "getent group #{options[:group]}"
              machine.communicate.execute(gid_command,
                error_class: Vagrant::Errors::VirtualBoxMountFailed,
                error_key: :virtualbox_mount_failed,
                command: gid_command,
                output: output[:stderr]
              ) { |type, data| output[type] << data if output[type] }
              mount_gid = output[:stdout].split(':').at(2)
              @@logger.debug("Owner group ID (lookup): #{options[:group]} -> #{mount_gid}")
            rescue Vagrant::Errors::VirtualBoxMountFailed
              if options[:owner] == options[:group]
                @@logger.debug("Failed to locate group `#{options[:group]}`. Group name matches owner. Fetching effective group ID.")
                output = {stdout: ''}
                result = machine.communicate.execute("id -g #{options[:owner]}",
                  error_check: false
                ) { |type, data| output[type] << data if output[type] }
                mount_gid = output[:stdout].chomp if result == 0
                @@logger.debug("Owner group ID (effective): #{mount_gid}")
              end
              raise unless mount_gid
            end
          end

          mount_options = options.fetch(:mount_options, [])
          mount_options += ["uid=#{mount_uid}", "gid=#{mount_gid}"]
          mount_options = mount_options.join(',')
          mount_command = "mount -t vboxsf -o #{mount_options} #{name} #{guest_path}"

          # Create the guest path if it doesn't exist
          machine.communicate.sudo("mkdir -p #{guest_path}")

          # Attempt to mount the folder. We retry here a few times because
          # it can fail early on.
          stderr = ""
          retryable(on: Vagrant::Errors::VirtualBoxMountFailed, tries: 3, sleep: 5) do
            machine.communicate.sudo(mount_command,
              error_class: Vagrant::Errors::VirtualBoxMountFailed,
              error_key: :virtualbox_mount_failed,
              command: mount_command,
              output: stderr,
            ) { |type, data| stderr = data if type == :stderr }
          end

          # Chown the directory to the proper user. We skip this if the
          # mount options contained a readonly flag, because it won't work.
          if !options[:mount_options] || !options[:mount_options].include?("ro")
            chown_command = "chown #{mount_uid}:#{mount_gid} #{guest_path}"
            machine.communicate.sudo(chown_command)
          end

          # Emit an upstart event if we can
          machine.communicate.sudo <<-EOH.gsub(/^ {12}/, "")
            if command -v /sbin/init && /sbin/init 2>/dev/null --version | grep upstart; then
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
