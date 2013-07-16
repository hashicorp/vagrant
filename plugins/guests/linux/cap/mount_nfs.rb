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

            # Do the actual creating and mounting
            machine.communicate.sudo("mkdir -p #{expanded_guest_path}")

            # Mount
            hostpath = opts[:hostpath].dup
            hostpath.gsub!("'", "'\\\\''")
            mount_command = "mount -o vers=#{opts[:nfs_version]} #{ip}:'#{hostpath}' #{expanded_guest_path}"

            retryable(:on => Vagrant::Errors::LinuxNFSMountFailed, :tries => 5, :sleep => 2) do
              machine.communicate.sudo(mount_command,
                                       :error_class => Vagrant::Errors::LinuxNFSMountFailed)
            end
          end
        end
      end
    end
  end
end
