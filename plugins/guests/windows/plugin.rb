require "vagrant"

module VagrantPlugins
  module GuestWindows
    class Plugin < Vagrant.plugin("2")
      name "Windows guest."
      description "Windows guest support."

      config("windows") do
        require_relative "config"
        Config
      end

      guest("windows")  do
        require_relative "guest"
        Guest
      end

      guest_capability(:windows, :change_host_name) do
        require_relative "cap/change_host_name"
        Cap::ChangeHostName
      end

      guest_capability(:windows, :configure_networks) do
        require_relative "cap/configure_networks"
        Cap::ConfigureNetworks
      end

      guest_capability(:windows, :halt) do
        require_relative "cap/halt"
        Cap::Halt
      end

      guest_capability(:windows, :mount_virtualbox_shared_folder) do
        require_relative "cap/mount_shared_folder"
        Cap::MountSharedFolder
      end

      guest_capability(:windows, :mount_vmware_shared_folder) do
        require_relative "cap/mount_shared_folder"
        Cap::MountSharedFolder
      end

      guest_capability(:windows, :mount_parallels_shared_folder) do
        require_relative "cap/mount_shared_folder"
        Cap::MountSharedFolder
      end
    end
  end
end
