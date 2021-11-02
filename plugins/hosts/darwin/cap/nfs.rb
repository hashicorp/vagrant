module VagrantPlugins
  module HostDarwin
    module Cap
      class NFS
        def self.nfs_exports_template(environment)
          "nfs/exports_darwin"
        end
        
        def self.nfs_restart_command(environment)
          ["sudo", "nfsd", "update"]
        end
      end
    end
  end
end
