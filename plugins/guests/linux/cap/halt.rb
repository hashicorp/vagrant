module VagrantPlugins
  module GuestLinux
    module Cap
      class Halt
        def self.halt(machine)
          # unmount any host mounted NFS folders
          folders = machine.config.vm.synced_folders
          machine.env.host.unmount_nfs_folders(folders)

          begin
            machine.communicate.sudo("shutdown -h now")
          rescue IOError
            # Do nothing, because it probably means the machine shut down
            # and SSH connection was lost.
          end
        end
      end
    end
  end
end
