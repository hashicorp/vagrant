module VagrantPlugins
  module HostWindows
    module Cap
      class NFS
        def self.nfs_installed(_env)
          false
        end
      end
    end
  end
end
