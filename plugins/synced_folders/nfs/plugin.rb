require "vagrant"

module VagrantPlugins
  module SyncedFolderNFS
    class Plugin < Vagrant.plugin("2")
      name "NFS synced folders"
      description <<-EOF
      The NFS synced folders plugin enables you to use NFS as a synced folder
      implementation.
      EOF

      synced_folder(:nfs, 5) do
        require File.expand_path("../synced_folder", __FILE__)
        SyncedFolder
      end
    end
  end
end
