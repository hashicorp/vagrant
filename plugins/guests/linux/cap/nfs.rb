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

          # Mount each folder separately so we can retry.
          folders.each do |name, opts|
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

            machine.communicate.sudo("mkdir -p #{guest_path}")

            # Perform the mount operation and emit mount event if applicable
            command = <<-EOH.gsub(/^ */, '')
              mount -o #{mount_opts} #{ip}:#{host_path} #{guest_path}
              result=$?
              if test $result -eq 0; then
                if test -x /sbin/initctl && command -v /sbin/init && /sbin/init 2>/dev/null --version | grep upstart; then
                  /sbin/initctl emit --no-wait vagrant-mounted MOUNTPOINT=#{guest_path}
                fi
              else
                exit $result
              fi
            EOH

            # Run the command, raising a specific error.
            retryable(on: Vagrant::Errors::NFSMountFailed, tries: 3, sleep: 5) do
              machine.communicate.sudo(command,
                error_class: Vagrant::Errors::NFSMountFailed,
              )
            end
          end
        end
      end
    end
  end
end
