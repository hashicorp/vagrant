module VagrantPlugins
  module GuestNetBSD
    module Cap
      class MountNFSFolder
        def self.mount_nfs_folder(machine, ip, folders)
          folders.each do |name, opts|
            machine.communicate.sudo(<<CMDS, {shell: "sh"})
set -e
mkdir -p #{opts[:guestpath]}
/sbin/mount -t nfs '#{ip}:#{opts[:hostpath]}' '#{opts[:guestpath]}'
CMDS
          end
        end
      end
    end
  end
end
