require "vagrant/util/retryable"

module VagrantPlugins
  module GuestFreeBSD
    module Cap
      class MountNFSFolder
        extend Vagrant::Util::Retryable

        def self.mount_nfs_folder(machine, ip, folders)
          comm = machine.communicate

          commands = []

          folders.each do |name, opts|
            # Expand the guest path so we can handle things like "~/vagrant"
            expanded_guest_path = machine.guest.capability(
              :shell_expand_guest_path, opts[:guestpath])

            # Do the actual creating and mounting
            commands << "mkdir -p '#{expanded_guest_path}'"

            # Mount
            hostpath = opts[:hostpath].dup
            hostpath.gsub!("'", "'\\\\''")

            # Figure out any options
            mount_opts = ["nfsv#{opts[:nfs_version]}"]
            mount_opts << "udp" if opts[:nfs_udp]
            if opts[:mount_options]
              mount_opts = opts[:mount_options].dup
            end

            commands << "mount -t nfs -o #{mount_opts.join(",")} '#{ip}:#{hostpath}' '#{expanded_guest_path}'"
          end

          retryable(on: Vagrant::Errors::FreeBSDNFSMountFailed, tries: 8, sleep: 3) do
            comm.sudo(commands.join("\n"), error_class: Vagrant::Errors::FreeBSDNFSMountFailed)
          end
        end
      end
    end
  end
end
