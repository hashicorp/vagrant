require "vagrant"

module VagrantPlugins
  module GuestEsxi
    class Plugin < Vagrant.plugin("2")
      name "ESXi guest."
      description "ESXi guest support."

      guest(:esxi)  do
        require_relative "guest"
        Guest
      end

      guest_capability(:esxi, :change_host_name) do
        require_relative "cap/change_host_name"
        Cap::ChangeHostName
      end

      guest_capability(:esxi, :configure_networks) do
        require_relative "cap/configure_networks"
        Cap::ConfigureNetworks
      end

      guest_capability(:esxi, :mount_nfs_folder) do
        require_relative "cap/mount_nfs_folder"
        Cap::MountNFSFolder
      end

      guest_capability(:esxi, :halt) do
        require_relative "cap/halt"
        Cap::Halt
      end
      
      guest_capability(:esxi, :remove_public_key) do
        require_relative "cap/public_key"
        Cap::PublicKey
      end
      
      guest_capability(:esxi, :insert_public_key) do
        require_relative "cap/public_key"
        Cap::PublicKey
      end
      
    end
  end
end
