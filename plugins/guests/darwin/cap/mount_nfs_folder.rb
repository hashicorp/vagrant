require "vagrant/util/retryable"

module VagrantPlugins
  module GuestDarwin
    module Cap
      class MountNFSFolder
        extend Vagrant::Util::Retryable
        def self.mount_nfs_folder(machine, ip, folders)
          folders.each do |name, opts|
            # Expand the guest path so we can handle things like "~/vagrant"
            expanded_guest_path = machine.guest.capability(
              :shell_expand_guest_path, opts[:guestpath])

              machine.communicate.sudo("if [ ! -d  #{expanded_guest_path} ]; then  mkdir -p #{expanded_guest_path};fi")

              mount_command = "mount -t nfs '#{ip}:#{opts[:hostpath]}' '#{expanded_guest_path}'"
              retryable(:on => Vagrant::Errors::DarwinNFSMountFailed, :tries => 10, :sleep => 5) do
                machine.communicate.sudo(mount_command, :error_class => Vagrant::Errors::DarwinNFSMountFailed)
              end
          end
        end
      end
    end
  end
end
