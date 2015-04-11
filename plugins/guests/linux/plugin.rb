require "vagrant"

module VagrantPlugins
  module GuestLinux
    class Plugin < Vagrant.plugin("2")
      name "Linux guest."
      description "Linux guest support."

      guest("linux")  do
        require File.expand_path("../guest", __FILE__)
        Guest
      end

      guest_capability("linux", "choose_addressable_ip_addr") do
        require_relative "cap/choose_addressable_ip_addr"
        Cap::ChooseAddressableIPAddr
      end

      guest_capability("linux", "halt") do
        require_relative "cap/halt"
        Cap::Halt
      end

      guest_capability("linux", "insert_public_key") do
        require_relative "cap/insert_public_key"
        Cap::InsertPublicKey
      end

      guest_capability("linux", "shell_expand_guest_path") do
        require_relative "cap/shell_expand_guest_path"
        Cap::ShellExpandGuestPath
      end

      guest_capability("linux", "mount_nfs_folder") do
        require_relative "cap/mount_nfs"
        Cap::MountNFS
      end

      guest_capability("linux", "mount_smb_shared_folder") do
        require_relative "cap/mount_smb_shared_folder"
        Cap::MountSMBSharedFolder
      end

      guest_capability("linux", "mount_virtualbox_shared_folder") do
        require_relative "cap/mount_virtualbox_shared_folder"
        Cap::MountVirtualBoxSharedFolder
      end

      guest_capability("linux", "nfs_client_installed") do
        require_relative "cap/nfs_client"
        Cap::NFSClient
      end

      # For the Docker provider
      guest_capability("linux", "port_open_check") do
        require_relative "cap/port"
        Cap::Port
      end

      guest_capability("linux", "read_ip_address") do
        require_relative "cap/read_ip_address"
        Cap::ReadIPAddress
      end

      guest_capability("linux", "remove_public_key") do
        require_relative "cap/remove_public_key"
        Cap::RemovePublicKey
      end

      guest_capability("linux", "rsync_installed") do
        require_relative "cap/rsync"
        Cap::RSync
      end

      guest_capability("linux", "rsync_command") do
        require_relative "cap/rsync"
        Cap::RSync
      end

      guest_capability("linux", "rsync_post") do
        require_relative "cap/rsync"
        Cap::RSync
      end

      guest_capability("linux", "rsync_pre") do
        require_relative "cap/rsync"
        Cap::RSync
      end

      guest_capability("linux", "unmount_virtualbox_shared_folder") do
        require_relative "cap/mount_virtualbox_shared_folder"
        Cap::MountVirtualBoxSharedFolder
      end
    end
  end
end
