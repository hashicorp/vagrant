module VagrantPlugins
  module GuestOmniOS
    module Cap
      class MountNFSFolder
        def self.mount_nfs_folder(machine, ip, folders)
          comm   = machine.communicate
          commands = []

          folders.each do |_, opts|
            commands << <<-EOH.gsub(/^ {14}/, '')
              mkdir -p '#{opts[:guestpath]}'
              /sbin/mount '#{ip}:#{opts[:hostpath]}' '#{opts[:guestpath]}'
            EOH
          end

          comm.sudo(commands.join("\n"))
        end
      end
    end
  end
end
