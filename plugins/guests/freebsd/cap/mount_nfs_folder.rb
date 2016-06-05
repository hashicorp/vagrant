module VagrantPlugins
  module GuestFreeBSD
    module Cap
      class MountNFSFolder
        def self.mount_nfs_folder(machine, ip, folders)
          comm = machine.communicate

          commands = []

          folders.each do |_, opts|
            if opts[:nfs_version]
              mount_opts = "-o nfsv#{opts[:nfs_version]}"
            end

            commands << "mkdir -p '#{opts[:guestpath]}'"
            commands << "mount -t nfs #{mount_opts} '#{ip}:#{opts[:hostpath]}' '#{opts[:guestpath]}'"
          end

          comm.sudo(commands.join("\n"), { shell: "sh" })
        end
      end
    end
  end
end
