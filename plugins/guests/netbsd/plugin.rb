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

      guest_capability("netbsd", "rsync_pre") do
        require_relative "cap/rsync"
        Cap::RSync
      end
    end
  end
end
