# A general Vagrant system implementation for "solaris 11".
#
# Contributed by Jan Thomas Moldung <janth@moldung.no>

require "vagrant"

module VagrantPlugins
  module GuestSolaris11
    class Plugin < Vagrant.plugin("2")
      name "Solaris 11 guest."
      description "Solaris 11 guest support."

      config("solaris11") do
        require File.expand_path("../config", __FILE__)
        Config
      end

      guest("solaris11")  do
        require File.expand_path("../guest", __FILE__)
        Guest
      end

      guest_capability("solaris11", "change_host_name") do
        require_relative "cap/change_host_name"
        Cap::ChangeHostName
      end

      guest_capability("solaris11", "configure_networks") do
        require_relative "cap/configure_networks"
        Cap::ConfigureNetworks
      end

      guest_capability("solaris11", "halt") do
        require_relative "cap/halt"
        Cap::Halt
      end

      guest_capability("solaris11", "mount_virtualbox_shared_folder") do
        require_relative "cap/mount_virtualbox_shared_folder"
        Cap::MountVirtualBoxSharedFolder
      end

      guest_capability("solaris11", "rsync_installed") do
        require_relative "cap/rsync"
        Cap::RSync
      end

      guest_capability("solaris11", "rsync_pre") do
        require_relative "cap/rsync"
        Cap::RSync
      end

      guest_capability("solaris11", "insert_public_key") do
        require_relative "cap/insert_public_key"
        Cap::InsertPublicKey
      end

      guest_capability("solaris11", "remove_public_key") do
        require_relative "cap/remove_public_key"
        Cap::RemovePublicKey
      end
    end
  end
end
