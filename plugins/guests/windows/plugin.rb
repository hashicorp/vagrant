require "vagrant"

module VagrantPlugins
  module GuestWindows
    autoload :Errors, File.expand_path("../errors", __FILE__)

    class Plugin < Vagrant.plugin("2")
      name "Windows guest."
      description "Windows guest support."

      config("windows") do
        require_relative "config"
        Config
      end

      guest("windows")  do
        require_relative "guest"
        init!
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

      guest_capability(:windows, :wait_for_reboot) do
        require_relative "cap/reboot"
        Cap::Reboot
      end

      guest_capability(:windows, :choose_addressable_ip_addr) do
        require_relative "cap/choose_addressable_ip_addr"
        Cap::ChooseAddressableIPAddr
      end

      guest_capability(:windows, :mount_smb_shared_folder) do
        require_relative "cap/mount_shared_folder"
        Cap::MountSharedFolder
      end

      guest_capability(:windows, :rsync_pre) do
        require_relative "cap/rsync"
        Cap::RSync
      end

      protected

      def self.init!
        return if defined?(@_init)
        I18n.load_path << File.expand_path(
          "templates/locales/guest_windows.yml", Vagrant.source_root)
        I18n.reload!
        @_init = true
      end
    end
  end
end
