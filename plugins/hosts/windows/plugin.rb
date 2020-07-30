require "vagrant"

module VagrantPlugins
  module HostWindows
    class Plugin < Vagrant.plugin("2")
      name "Windows host"
      description "Windows host support."

      host("windows") do
        require_relative "host"
        Host
      end

      host_capability("windows", "isofs_available") do
        require_relative "cap/fs_iso"
        Cap::FsISO
      end

      host_capability("windows", "create_iso") do
        require_relative "cap/fs_iso"
        Cap::FsISO
      end

      host_capability("windows", "provider_install_virtualbox") do
        require_relative "cap/provider_install_virtualbox"
        Cap::ProviderInstallVirtualBox
      end

      host_capability("windows", "nfs_installed") do
        require_relative "cap/nfs"
        Cap::NFS
      end

      host_capability("windows", "rdp_client") do
        require_relative "cap/rdp"
        Cap::RDP
      end

      host_capability("windows", "ps_client") do
        require_relative "cap/ps"
        Cap::PS
      end

      host_capability("windows", "smb_installed") do
        require_relative "cap/smb"
        Cap::SMB
      end

      host_capability("windows", "smb_prepare") do
        require_relative "cap/smb"
        Cap::SMB
      end

      host_capability("windows", "smb_cleanup") do
        require_relative "cap/smb"
        Cap::SMB
      end

      host_capability("windows", "smb_mount_options") do
        require_relative "cap/smb"
        Cap::SMB
      end

      host_capability("windows", "configured_ip_addresses") do
        require_relative "cap/configured_ip_addresses"
        Cap::ConfiguredIPAddresses
      end

      host_capability("windows", "set_ssh_key_permissions") do
        require_relative "cap/ssh"
        Cap::SSH
      end

      host_capability("windows", "smb_validate_password") do
        require_relative "cap/smb"
        Cap::SMB
      end
    end
  end
end
