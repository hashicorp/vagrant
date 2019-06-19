require "vagrant"

module VagrantPlugins
  module GuestDebian
    class Plugin < Vagrant.plugin("2")
      name "Debian guest"
      description "Debian guest support."

      guest(:debian, :linux) do
        require_relative "guest"
        Guest
      end

      guest_capability(:debian, :configure_networks) do
        require_relative "cap/configure_networks"
        Cap::ConfigureNetworks
      end

      guest_capability(:debian, :change_host_name) do
        require_relative "cap/change_host_name"
        Cap::ChangeHostName
      end

      guest_capability(:debian, :nfs_client_install) do
        require_relative "cap/nfs"
        Cap::NFS
      end

      guest_capability(:debian, :rsync_install) do
        require_relative "cap/rsync"
        Cap::RSync
      end

      guest_capability(:debian, :smb_install) do
        require_relative "cap/smb"
        Cap::SMB
      end

      guest_capability(:debian, :hyperv_daemons_installed) do
        require_relative "cap/hyperv_daemons"
        Cap::HypervDaemons
      end

      guest_capability(:debian, :hyperv_daemons_install) do
        require_relative "cap/hyperv_daemons"
        Cap::HypervDaemons
      end
    end
  end
end
