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

      host_capability("darwin", "provider_install_virtualbox") do
        require_relative "cap/provider_install_virtualbox"
        Cap::ProviderInstallVirtualBox
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
    end
  end
end
