require "vagrant"

module VagrantPlugins
  module HostDarwin
    class Plugin < Vagrant.plugin("2")
      name "Mac OS X host"
      description "Mac OS X host support."

      host("darwin", "bsd") do
        require_relative "host"
        Host
      end

      host_capability("darwin", "isofs_available") do
        require_relative "cap/fs_iso"
        Cap::FsISO
      end

      host_capability("darwin", "create_iso") do
        require_relative "cap/fs_iso"
        Cap::FsISO
      end

      host_capability("darwin", "provider_install_virtualbox") do
        require_relative "cap/provider_install_virtualbox"
        Cap::ProviderInstallVirtualBox
      end

      host_capability("darwin", "resolve_host_path") do
        require_relative "cap/path"
        Cap::Path
      end

      host_capability("darwin", "rdp_client") do
        require_relative "cap/rdp"
        Cap::RDP
      end

      host_capability("darwin", "smb_installed") do
        require_relative "cap/smb"
        Cap::SMB
      end

      host_capability("darwin", "smb_prepare") do
        require_relative "cap/smb"
        Cap::SMB
      end

      host_capability("darwin", "smb_mount_options") do
        require_relative "cap/smb"
        Cap::SMB
      end

      host_capability("darwin", "smb_cleanup") do
        require_relative "cap/smb"
        Cap::SMB
      end

      host_capability("darwin", "smb_start") do
        require_relative "cap/smb"
        Cap::SMB
      end

      host_capability("darwin", "configured_ip_addresses") do
        require_relative "cap/configured_ip_addresses"
        Cap::ConfiguredIPAddresses
      end

      host_capability("darwin", "nfs_exports_template") do
        require_relative "cap/nfs"
        Cap::NFS
      end
    end
  end
end
