module VagrantPlugins
  module GuestOmniOS
    module Cap
      class MountNFSFolder
        def self.mount_nfs_folder(machine, ip, folders)
          su_cmd = machine.config.solaris.suexec_cmd
          folders.each do |name, opts|
            machine.communicate.execute("#{su_cmd} mkdir -p #{opts[:guestpath]}")
            machine.communicate.execute("#{su_cmd} /sbin/mount '#{ip}:#{opts[:hostpath]}' '#{opts[:guestpath]}'")
          end
        end
      end
    end
  end
end
