require "vagrant"

module VagrantPlugins
  module GuestFreeBSD
    class Plugin < Vagrant.plugin("2")
      name "FreeBSD guest"
      description "FreeBSD guest support."

      guest("freebsd")  do
        require File.expand_path("../guest", __FILE__)
        Guest
      end

      guest_capability("freebsd", "change_host_name") do
        require_relative "cap/change_host_name"
        Cap::ChangeHostName
      end

      guest_capability("freebsd", "configure_networks") do
        require_relative "cap/configure_networks"
        Cap::ConfigureNetworks
      end

      guest_capability("freebsd", "halt") do
        require_relative "cap/halt"
        Cap::Halt
      end

      guest_capability("freebsd", "mount_nfs_folder") do
        require_relative "cap/mount_nfs_folder"
        Cap::MountNFSFolder
      end
    end
  end
end
