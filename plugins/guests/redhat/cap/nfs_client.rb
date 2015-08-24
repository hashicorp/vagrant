module VagrantPlugins
  module GuestRedHat
    module Cap
      class NFSClient
        def self.nfs_client_install(machine)
          machine.communicate.sudo("yum -y install nfs-utils nfs-utils-lib")
          restart_nfs(machine)
        end

        def self.nfs_client_installed(machine)
          installed = machine.communicate.test("test -x /sbin/mount.nfs")
          restart_nfs(machine) if installed
          installed
        end

        protected

        def self.systemd?(machine)
          machine.communicate.test("test $(ps -o comm= 1) == 'systemd'")
        end

        def self.restart_nfs(machine)
          if systemd?(machine)
            machine.communicate.sudo("/bin/systemctl restart rpcbind nfs")
          else
            machine.communicate.sudo("/etc/init.d/rpcbind restart; /etc/init.d/nfs restart")
          end
        end
      end
    end
  end
end
