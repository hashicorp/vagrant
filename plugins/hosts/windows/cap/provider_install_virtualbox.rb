require "pathname"
require "tempfile"

require "vagrant/util/downloader"
require "vagrant/util/file_checksum"
require "vagrant/util/powershell"
require "vagrant/util/subprocess"

module VagrantPlugins
  module HostWindows
    module Cap
      class ProviderInstallVirtualBox
        # The URL to download VirtualBox is hardcoded so we can have a
        # known-good version to download.
        URL = "http://download.virtualbox.org/virtualbox/5.0.10/VirtualBox-5.0.10-104061-Win.exe".freeze
        VERSION = "5.0.10".freeze
        SHA256SUM = "3e5ed8fe4ada6eef8dfb4fe6fd79fcab4b242acf799f7d3ab4a17b43838b1e04".freeze

        def self.provider_install_virtualbox(env)
          path = Dir::Tmpname.create("vagrant-provider-install-virtualbox") {}

          # Prefixed UI for prettiness
          ui = Vagrant::UI::Prefixed.new(env.ui, "")

          # Start by downloading the file using the standard mechanism
          ui.output(I18n.t(
            "vagrant.hosts.windows.virtualbox_install_download",
            version: VERSION))
          ui.detail(I18n.t(
            "vagrant.hosts.windows.virtualbox_install_detail"))
          dl = Vagrant::Util::Downloader.new(URL, path, ui: ui)
          dl.download!

          # Validate that the file checksum matches
          actual = FileChecksum.new(path, Digest::SHA2).checksum
          if actual != SHA256SUM
            raise Vagrant::Errors::ProviderChecksumMismatch,
              provider: "virtualbox",
              actual: actual,
              expected: SHA256SUM
          end

          # Launch it
          ui.output(I18n.t(
            "vagrant.hosts.windows.virtualbox_install_install"))
          ui.detail(I18n.t(
            "vagrant.hosts.windows.virtualbox_install_install_detail"))
          script = File.expand_path("../../scripts/install_virtualbox.ps1", __FILE__)
          result = Vagrant::Util::PowerShell.execute(script, path)
          if result.exit_code != 0
            raise Vagrant::Errors::ProviderInstallFailed,
              provider: "virtualbox",
              stdout: result.stdout,
              stderr: result.stderr
          end

          ui.success(I18n.t("vagrant.hosts.windows.virtualbox_install_success"))
        end
      end
    end
  end
end
