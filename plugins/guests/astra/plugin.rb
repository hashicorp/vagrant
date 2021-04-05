require "vagrant"

module VagrantPlugins
  module GuestAstra
    class Plugin < Vagrant.plugin("2")
      name "Astra Linux guest"
      description "Astra Linux guest support."

      guest(:astra, :linux) do
        require_relative "guest"
        Guest
      end

      guest_capability(:astra, :configure_networks) do
        require_relative "cap/configure_networks"
        Cap::ConfigureNetworks
      end

      guest_capability(:astra, :change_host_name) do
        require_relative "cap/change_host_name"
        Cap::ChangeHostName
      end

      guest_capability(:astra, :nfs_client_install) do
        require_relative "cap/nfs"
        Cap::NFS
      end

      guest_capability(:astra, :rsync_install) do
        require_relative "cap/rsync"
        Cap::RSync
      end

      guest_capability(:astra, :smb_install) do
        require_relative "cap/smb"
        Cap::SMB
      end
    end
  end
end
