require "vagrant"

module VagrantPlugins
  module GuestDevuan
    class Plugin < Vagrant.plugin("2")
      name "Devuan guest"
      description "Devuan guest support."

      guest(:devuan, :linux) do
        require_relative "guest"
        Guest
      end

      guest_capability(:devuan, :configure_networks) do
        require_relative "cap/configure_networks"
        Cap::ConfigureNetworks
      end

      guest_capability(:devuan, :change_host_name) do
        require_relative "cap/change_host_name"
        Cap::ChangeHostName
      end

      guest_capability(:devuan, :nfs_client_install) do
        require_relative "cap/nfs"
        Cap::NFS
      end

      guest_capability(:devuan, :rsync_install) do
        require_relative "cap/rsync"
        Cap::RSync
      end

      guest_capability(:devuan, :smb_install) do
        require_relative "cap/smb"
        Cap::SMB
      end
    end
  end
end
