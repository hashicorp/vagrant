require "vagrant"

module VagrantPlugins
  module SyncedFolderSMB
    autoload :Errors, File.expand_path("../errors", __FILE__)

    # This plugin implements SMB synced folders.
    class Plugin < Vagrant.plugin("2")
      name "SMB synced folders"
      description <<-EOF
      The SMB synced folders plugin enables you to use SMB folders on
      Windows and share them to guest machines.
      EOF

      synced_folder("smb", 7) do
        require_relative "synced_folder"
        init!
        SyncedFolder
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
