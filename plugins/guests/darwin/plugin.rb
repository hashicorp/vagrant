require "vagrant"

module VagrantPlugins
  module GuestDarwin
    class Plugin < Vagrant.plugin("2")
      name "Darwin guest"
      description "Darwin guest support."

      action_hook(:apfs_firmlinks, :synced_folders) do |hook|
        require_relative "cap/mount_vmware_shared_folder"
        hook.prepend(Vagrant::Action::Builtin::Delayed, Cap::MountVmwareSharedFolder.method(:write_apfs_firmlinks))
      end

      guest(:darwin, :bsd)  do
        require_relative "guest"
        Guest
      end

      guest_capability(:darwin, :change_host_name) do
        require_relative "cap/change_host_name"
        Cap::ChangeHostName
      end

      guest_capability(:darwin, :choose_addressable_ip_addr) do
        require_relative "cap/choose_addressable_ip_addr"
        Cap::ChooseAddressableIPAddr
      end

      guest_capability(:darwin, :configure_networks) do
        require_relative "cap/configure_networks"
        Cap::ConfigureNetworks
      end

      guest_capability(:darwin, :darwin_version) do
        require_relative "cap/darwin_version"
        Cap::DarwinVersion
      end

      guest_capability(:darwin, :darwin_major_version) do
        require_relative "cap/darwin_version"
        Cap::DarwinVersion
      end

      guest_capability(:darwin, :halt) do
        require_relative "cap/halt"
        Cap::Halt
      end

      guest_capability(:darwin, :mount_smb_shared_folder) do
        require_relative "cap/mount_smb_shared_folder"
        Cap::MountSMBSharedFolder
      end

      guest_capability(:darwin, :mount_vmware_shared_folder) do
        require_relative "cap/mount_vmware_shared_folder"
        Cap::MountVmwareSharedFolder
      end

      guest_capability(:darwin, :rsync_installed) do
        require_relative "cap/rsync"
        Cap::RSync
      end

      guest_capability(:darwin, :rsync_command) do
        require_relative "cap/rsync"
        Cap::RSync
      end

      guest_capability(:darwin, :rsync_post) do
        require_relative "cap/rsync"
        Cap::RSync
      end

      guest_capability(:darwin, :rsync_pre) do
        require_relative "cap/rsync"
        Cap::RSync
      end

      guest_capability(:darwin, :shell_expand_guest_path) do
        require_relative "cap/shell_expand_guest_path"
        Cap::ShellExpandGuestPath
      end

      guest_capability(:darwin, :verify_vmware_hgfs) do
        require_relative "cap/verify_vmware_hgfs"
        Cap::VerifyVmwareHgfs
      end
    end
  end
end
