require "vagrant"

module VagrantPlugins
  module GuestNetBSD
    class Plugin < Vagrant.plugin("2")
      name "NetBSD guest"
      description "NetBSD guest support."

      guest("netbsd") do
        require File.expand_path("../guest", __FILE__)
        Guest
      end

      guest_capability("netbsd", "change_host_name") do
        require_relative "cap/change_host_name"
        Cap::ChangeHostName
      end

      guest_capability("netbsd", "configure_networks") do
        require_relative "cap/configure_networks"
        Cap::ConfigureNetworks
      end

      guest_capability("netbsd", "halt") do
        require_relative "cap/halt"
        Cap::Halt
      end

      guest_capability("netbsd", "insert_public_key") do
        require_relative "cap/insert_public_key"
        Cap::InsertPublicKey
      end

      guest_capability("netbsd", "mount_nfs_folder") do
        require_relative "cap/mount_nfs_folder"
        Cap::MountNFSFolder
      end

      guest_capability("netbsd", "rsync_install") do
        require_relative "cap/rsync"
        Cap::RSync
      end

      guest_capability("netbsd", "rsync_installed") do
        require_relative "cap/rsync"
        Cap::RSync
      end

      guest_capability("netbsd", "rsync_command") do
        require_relative "cap/rsync"
        Cap::RSync
      end

      guest_capability("netbsd", "rsync_post") do
        require_relative "cap/rsync"
        Cap::RSync
      end

      guest_capability("netbsd", "shell_expand_guest_path") do
        require_relative "cap/shell_expand_guest_path"
        Cap::ShellExpandGuestPath
      end
    end
  end
end
