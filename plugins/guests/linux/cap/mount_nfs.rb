require "vagrant/util/retryable"

module VagrantPlugins
  module GuestLinux
    module Cap
      class MountNFS
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
            mount_opts = ["vers=#{opts[:nfs_version]}"]
            mount_opts << "udp" if opts[:nfs_udp]
            if opts[:mount_options]
              mount_opts = opts[:mount_options].dup
            end

            commands << "mount -o #{mount_opts.join(",")} '#{ip}:#{hostpath}' '#{expanded_guest_path}'"

            # Emit a mount event
            commands << <<-EOH.gsub(/^ {14}/, '')
              if command -v /sbin/init && /sbin/init --version | grep upstart; then
                /sbin/initctl emit --no-wait vagrant-mounted MOUNTPOINT='#{expanded_guest_path}'
              fi
            EOH
          end

          retryable(on: Vagrant::Errors::LinuxNFSMountFailed, tries: 8, sleep: 3) do
            comm.sudo(commands.join("\n"), error_class: Vagrant::Errors::LinuxNFSMountFailed)
          end
        end
      end
    end
  end
end
