module VagrantPlugins
  module HyperV
    autoload :Action, File.expand_path("../action", __FILE__)
    autoload :Errors, File.expand_path("../errors", __FILE__)

    class Plugin < Vagrant.plugin("2")
      name "Hyper-V provider"
      description <<-DESC
      This plugin installs a provider that allows Vagrant to manage
      machines in Hyper-V.
      DESC

      provider(:hyperv, priority: 4) do
        require_relative "provider"
        init!
        Provider
      end

      synced_folder(:hyperv) do
        require File.expand_path("../synced_folder", __FILE__)
        SyncedFolder
      end

      config(:hyperv, :provider) do
        require_relative "config"
        init!
        Config
      end

      provider_capability("hyperv", "public_address") do
        require_relative "cap/public_address"
        Cap::PublicAddress
      end

      provider_capability("hyperv", "snapshot_list") do
        require_relative "cap/snapshot_list"
        Cap::SnapshotList
      end

      command("hyperv-sync", primary: false) do
        require_relative "command/sync"
        Command::Sync
      end

      command("hyperv-sync-auto", primary: false) do
        require_relative "command/sync_auto"
        Command::SyncAuto
      end

      protected

      def self.init!
        return if defined?(@_init)
        I18n.load_path << File.expand_path(
          "templates/locales/providers_hyperv.yml", Vagrant.source_root)
        I18n.reload!
        @_init = true
      end
    end
  end
end
