require "vagrant"

module VagrantPlugins
  module GuestSmartos
    class Plugin < Vagrant.plugin("2")
      name "SmartOS guest."
      description "SmartOS guest support."

      config(:smartos) do
        require_relative "config"
        Config
      end

      guest(:smartos)  do
        require_relative "guest"
        Guest
      end

      guest_capability(:smartos, :change_host_name) do
        require_relative "cap/change_host_name"
        Cap::ChangeHostName
      end

      guest_capability(:smartos, :configure_networks) do
        require_relative "cap/configure_networks"
        Cap::ConfigureNetworks
      end

      guest_capability(:smartos, :halt) do
        require_relative "cap/halt"
        Cap::Halt
      end

      guest_capability(:smartos, :insert_public_key) do
        require_relative "cap/insert_public_key"
        Cap::InsertPublicKey
      end

      guest_capability(:smartos, :mount_nfs_folder) do
        require_relative "cap/mount_nfs"
        Cap::MountNFS
      end

      guest_capability(:smartos, :remove_public_key) do
        require_relative "cap/remove_public_key"
        Cap::RemovePublicKey
      end

      guest_capability(:smartos, :rsync_installed) do
        require_relative "cap/rsync"
        Cap::RSync
      end

      guest_capability(:smartos, :rsync_command) do
        require_relative "cap/rsync"
        Cap::RSync
      end

      guest_capability(:smartos, :rsync_post) do
        require_relative "cap/rsync"
        Cap::RSync
      end

      guest_capability(:smartos, :rsync_pre) do
        require_relative "cap/rsync"
        Cap::RSync
      end
    end
  end
end

