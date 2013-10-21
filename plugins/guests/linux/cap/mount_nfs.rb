require "vagrant/util/retryable"

module VagrantPlugins
  module GuestLinux
    module Cap
      class MountNFS
        extend Vagrant::Util::Retryable

        def self.mount_nfs_folder(machine, ip, folders)
          folders.each do |name, opts|
            # Expand the guest path so we can handle things like "~/vagrant"
            expanded_guest_path = machine.guest.capability(
              :shell_expand_guest_path, opts[:guestpath])

            #check if mounts are already there
            checkresult = machine.communicate.sudo("cat /etc/mtab | grep '#{expanded_guest_path} '", error_check: false)

            if checkresult != 0

              # Do the actual creating and mounting
              machine.communicate.sudo("mkdir -p #{expanded_guest_path}")

              # Mount
              hostpath = opts[:hostpath].dup
              hostpath.gsub!("'", "'\\\\''")

              # Figure out any options
              mount_opts = ["vers=#{opts[:nfs_version]}", "udp"]
              if opts[:mount_options]
                mount_opts = opts[:mount_options].dup
              end

              mount_command = "mount -o '#{mount_opts.join(",")}' #{ip}:'#{hostpath}' #{expanded_guest_path}"
              retryable(:on => Vagrant::Errors::LinuxNFSMountFailed, :tries => 5, :sleep => 2) do
                machine.communicate.sudo(mount_command,
                                         :error_class => Vagrant::Errors::LinuxNFSMountFailed)
              end

  			# add to fstab
  			machine.communicate.sudo("echo \"#{ip}:#{hostpath} #{expanded_guest_path} nfs #{mount_opts.join(",")} 0 0\" >> /etc/fstab");
            end
          end
        end
      end
    end
  end
end
