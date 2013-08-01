module VagrantPlugins
    module GuestDarwin
        module Cap
            class MountNFSFolder
                def self.mount_nfs_folder(machine, ip, folders)
                    puts "30 second nap...."
                    sleep(30)
                    folders.each do |name, opts|
                        machine.communicate.sudo("if [ ! -d  #{opts[:guestpath]} ]; then  mkdir -p #{opts[:guestpath]};fi")
                        machine.communicate.sudo("mount -t nfs '#{ip}:#{opts[:hostpath]}' '#{opts[:guestpath]}'")
                    end
                end
            end
        end
    end
end
