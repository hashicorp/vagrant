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

      provider_capability(:hyperv, :configure_disks) do
        require_relative "cap/configure_disks"
        Cap::ConfigureDisks
      end

      provider_capability(:hyperv, :cleanup_disks) do
        require_relative "cap/cleanup_disks"
        Cap::CleanupDisks
      end

      provider_capability(:hyperv, :validate_disk_ext) do
        require_relative "cap/validate_disk_ext"
        Cap::ValidateDiskExt
      end

      provider_capability(:hyperv, :default_disk_exts) do
        require_relative "cap/validate_disk_ext"
        Cap::ValidateDiskExt
      end

      provider_capability(:hyperv, :set_default_disk_ext) do
        require_relative "cap/validate_disk_ext"
        Cap::ValidateDiskExt
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
