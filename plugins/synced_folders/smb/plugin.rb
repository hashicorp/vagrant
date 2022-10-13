require "vagrant"

module VagrantPlugins
  module SyncedFolderSMB
    autoload :Errors, File.expand_path("../errors", __FILE__)

    # This plugin implements SMB synced folders.
    class Plugin < Vagrant.plugin("2")
      name "SMB synced folders"
      description <<-EOF
      The SMB synced folders plugin enables you to use SMB folders on
      Windows or macOS and share them to guest machines.
      EOF

      config("smb") do
        require_relative "config"
        Config
      end

      synced_folder("smb", 7) do
        require_relative "synced_folder"
        init!
        SyncedFolder
      end

      synced_folder_capability("smb", "default_fstab_modification") do
        require_relative "cap/default_fstab_modification"
        Cap::DefaultFstabModification
      end

      synced_folder_capability("smb", "mount_options") do
        require_relative "cap/mount_options"
        Cap::MountOptions
      end

      synced_folder_capability("smb", "mount_name") do
        require_relative "cap/mount_options"
        Cap::MountOptions
      end

      synced_folder_capability("smb", "mount_type") do
        require_relative "cap/mount_options"
        Cap::MountOptions
      end

      protected

      def self.init!
        return if defined?(@_init)
        I18n.load_path << File.expand_path(
          "templates/locales/synced_folder_smb.yml", Vagrant.source_root)
        I18n.reload!
        @_init = true
      end
    end
  end
end
