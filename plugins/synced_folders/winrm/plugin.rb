require "vagrant"

module VagrantPlugins
  module SyncedFolderWinRM
    # This plugin implements synced folders via winrm.
    class Plugin < Vagrant.plugin("2")
      name "WinRM synced folders"
      description <<-EOF
      The Rsync synced folder plugin will sync folders via winrm.
      EOF

      synced_folder("winrm", 1) do
        require_relative "synced_folder"
        SyncedFolder
      end
    end
  end
end
