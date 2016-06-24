require "vagrant/util/retryable"

module VagrantPlugins
  module GuestLinux
    module Cap
      class NFS
        extend Vagrant::Util::Retryable

        def self.nfs_client_installed(machine)
          machine.communicate.test("test -x /sbin/mount.nfs")
        end

        def self.mount_nfs_folder(machine, ip, folders)
          comm = machine.communicate

          folders.each do |name, opts|
            # Mount each folder separately so we can retry.
            commands = ["set -e"]

            # Shellescape the paths in case they do not have special characters.
            guest_path = Shellwords.escape(opts[:guestpath])
            host_path  = Shellwords.escape(opts[:hostpath])

            # Build the list of mount options.
            mount_opts =  []
            mount_opts << "vers=#{opts[:nfs_version]}" if opts[:nfs_version]
            mount_opts << "udp" if opts[:nfs_udp]
            if opts[:mount_options]
              mount_opts = mount_opts + opts[:mount_options].dup
            end
            mount_opts = mount_opts.join(",")

            # Make the directory on the guest.
            commands << "mkdir -p #{guest_path}"

            # Perform the mount operation.
            commands << "mount -o #{mount_opts} #{ip}:#{host_path} #{guest_path}"

            # Emit a mount event
            commands << <<-EOH.gsub(/^ {14}/, '')
              if command -v /sbin/init && /sbin/init --version | grep upstart; then
                /sbin/initctl emit --no-wait vagrant-mounted MOUNTPOINT=#{guest_path}
              fi
            EOH

            # Run the command, raising a specific error.
            retryable(on: Vagrant::Errors::NFSMountFailed, tries: 3, sleep: 5) do
              machine.communicate.sudo(commands.join("\n"),
                error_class: Vagrant::Errors::NFSMountFailed,
              )
            end
          end
        end
      end
    end
  end
end
