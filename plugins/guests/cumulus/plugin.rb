require "vagrant"

module VagrantPlugins
  module GuestCumulus
    class Plugin < Vagrant.plugin("2")
      name "Cumulus guest"
      description "Cumulus guest support."

      guest(:cumulus, :linux) do
        require_relative "guest"
        Guest
      end

      guest_capability(:cumulus, :configure_networks) do
        require_relative "cap/configure_networks"
        Cap::ConfigureNetworks
      end

      guest_capability(:cumulus, :change_host_name) do
        require_relative "cap/change_host_name"
        Cap::ChangeHostName
      end

      guest_capability(:cumulus, :nfs_client_install) do
        require_relative "cap/nfs"
        Cap::NFS
      end

      guest_capability(:cumulus, :rsync_install) do
        require_relative "cap/rsync"
        Cap::RSync
      end

      guest_capability(:cumulus, :smb_install) do
        require_relative "cap/smb"
        Cap::SMB
      end
    end
  end
end
