require "vagrant"

module VagrantPlugins
  module SyncedFolderRSync
    # This plugin implements synced folders via rsync.
    class Plugin < Vagrant.plugin("2")
      name "RSync synced folders"
      description <<-EOF
      The Rsync synced folder plugin will sync folders via rsync.
      EOF

      synced_folder("rsync", 5) do
        require_relative "synced_folder"
        SyncedFolder
      end
    end
  end
end
