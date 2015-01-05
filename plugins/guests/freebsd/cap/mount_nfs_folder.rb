module VagrantPlugins
  module GuestFreeBSD
    module Cap
      class MountNFSFolder
        def self.mount_nfs_folder(machine, ip, folders)
          folders.each do |name, opts|
            if opts[:nfs_version]
              nfs_version_mount_option="-o nfsv#{opts[:nfs_version]}"
            end

            machine.communicate.sudo("mkdir -p #{opts[:guestpath]}", {shell: "sh"})

            machine.communicate.sudo(
              "mount -t nfs #{nfs_version_mount_option} " +
              "'#{ip}:#{opts[:hostpath]}' '#{opts[:guestpath]}'", {shell: "sh"})
          end
        end
      end
    end
  end
end
