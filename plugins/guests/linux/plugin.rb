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

      guest_capability("linux", "halt") do
        require_relative "cap/halt"
        Cap::Halt
      end

      guest_capability("linux", "shell_expand_guest_path") do
        require_relative "cap/shell_expand_guest_path"
        Cap::ShellExpandGuestPath
      end

      guest_capability("linux", "mount_nfs_folder") do
        require_relative "cap/mount_nfs"
        Cap::MountNFS
      end

      guest_capability("linux", "mount_virtualbox_shared_folder") do
        require_relative "cap/mount_virtualbox_shared_folder"
        Cap::MountVirtualBoxSharedFolder
      end

      guest_capability("linux", "read_ip_address") do
        require_relative "cap/read_ip_address"
        Cap::ReadIPAddress
      end
    end
  end
end
