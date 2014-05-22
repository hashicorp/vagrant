module VagrantPlugins
  module GuestSmartos
    module Cap
      class MountNFS
        def self.mount_nfs_folder(machine, ip, folders)
          sudo = machine.config.smartos.suexec_cmd

          folders.each do |name, opts|
            machine.communicate.tap do |comm|
              comm.execute("#{sudo} mkdir -p #{opts[:guestpath]}", {shell: "sh"})
              comm.execute("#{sudo} /usr/sbin/mount -F nfs '#{ip}:#{opts[:hostpath]}' '#{opts[:guestpath]}'", {shell: "sh"})
            end
          end
        end
      end
    end
  end
end

