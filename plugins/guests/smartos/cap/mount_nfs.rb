module VagrantPlugins
  module GuestSmartos
    module Cap
      class MountNFS
        def self.mount_nfs_folder(machine, ip, folders)
          sudo = machine.config.smartos.suexec_cmd

          folders.each do |name, opts|
            machine.communicate.tap do |comm|
              nfsDescription = "#{ip}:#{opts[:hostpath]}:#{opts[:guestpath]}"

              comm.execute <<-EOH.sub(/^ */, '')
                if [ -d /usbkey ] && [ "$(zonename)" == "global" ] ; then
                  #{sudo} mkdir -p /usbkey/config.inc
                  printf '#{nfsDescription}\\n' | #{sudo} tee -a /usbkey/config.inc/nfs_mounts
                fi

                #{sudo} mkdir -p #{opts[:guestpath]}
                #{sudo} /usr/sbin/mount -F nfs '#{ip}:#{opts[:hostpath]}' '#{opts[:guestpath]}'
              EOH
            end
          end
        end
      end
    end
  end
end

