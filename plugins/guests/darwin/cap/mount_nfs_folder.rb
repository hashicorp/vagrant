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

            # Create the folder
            machine.communicate.sudo("mkdir -p #{expanded_guest_path}")

            # Figure out any options
            mount_opts = ["vers=#{opts[:nfs_version]}"]
            mount_opts << "udp" if opts[:nfs_udp]
            if opts[:mount_options]
              mount_opts = opts[:mount_options].dup
            end

            mount_command = "mount -t nfs " +
              "-o '#{mount_opts.join(",")}' " +
              "'#{ip}:#{opts[:hostpath]}' '#{expanded_guest_path}'"
            retryable(on: Vagrant::Errors::DarwinNFSMountFailed, tries: 10, sleep: 5) do
              machine.communicate.sudo(
                mount_command,
                error_class: Vagrant::Errors::DarwinNFSMountFailed)
            end
          end
        end
      end
    end
  end
end
