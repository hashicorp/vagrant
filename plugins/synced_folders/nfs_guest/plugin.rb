require "vagrant"

module VagrantPlugins
  module SyncedFolderNFSGuest
    class Plugin < Vagrant.plugin("2")
      name "NFS Guest synced folders"
      description <<-EOF
      The NFS Guest synced folders plugin enables you to use NFS as a synced folder
      implementation from the guest mounted on the host.
      EOF

      config("nfs_guest") do
        require File.expand_path("../config", __FILE__)
        Config
      end

      synced_folder("nfs_guest", 4) do
        require File.expand_path("../synced_folder", __FILE__)
        SyncedFolder
      end
    end
  end
end
