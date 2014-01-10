module VagrantPlugins
  module GuestLinux
    module Cap
      class NFSClient
        def self.nfs_client_installed(machine)
          machine.communicate.test("test -x /sbin/mount.nfs")
        end
      end
    end
  end
end
