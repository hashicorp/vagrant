require "vagrant"

module VagrantPlugins
  module GuestArch
    class Plugin < Vagrant.plugin("2")
      name "Arch guest"
      description "Arch guest support."

      guest(:arch, :linux) do
        require_relative "guest"
        Guest
      end

      guest_capability(:arch, :change_host_name) do
        require_relative "cap/change_host_name"
        Cap::ChangeHostName
      end

      guest_capability(:arch, :configure_networks) do
        require_relative "cap/configure_networks"
        Cap::ConfigureNetworks
      end

      guest_capability(:arch, :nfs_client_install) do
        require_relative "cap/nfs"
        Cap::NFS
      end

      guest_capability(:arch, :nfs_client_installed) do
        require_relative "cap/nfs"
        Cap::NFS
      end

      guest_capability(:arch, :nfs_pre) do
        require_relative "cap/nfs"
        Cap::NFS
      end

      guest_capability(:arch, :rsync_install) do
        require_relative "cap/rsync"
        Cap::RSync
      end

      guest_capability(:arch, :smb_install) do
        require_relative "cap/smb"
        Cap::SMB
      end

      guest_capability(:arch, :hyperv_daemons_installed) do
        require_relative "cap/hyperv_daemons"
        Cap::HypervDaemons
      end

      guest_capability(:arch, :hyperv_daemons_install) do
        require_relative "cap/hyperv_daemons"
        Cap::HypervDaemons
      end
    end
  end
end
