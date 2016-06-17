require "vagrant"

module VagrantPlugins
  module GuestSUSE
    class Plugin < Vagrant.plugin("2")
      name "SUSE guest"
      description "SUSE guest support."

      guest(:suse, :linux) do
        require_relative "guest"
        Guest
      end

      guest_capability(:suse, :change_host_name) do
        require_relative "cap/change_host_name"
        Cap::ChangeHostName
      end

      guest_capability(:suse, :configure_networks) do
        require_relative "cap/configure_networks"
        Cap::ConfigureNetworks
      end

      guest_capability(:suse, :halt) do
        require_relative "cap/halt"
        Cap::Halt
      end

      guest_capability(:suse, :network_scripts_dir) do
        require_relative "cap/network_scripts_dir"
        Cap::NetworkScriptsDir
      end

      guest_capability(:suse, :nfs_client_install) do
        require_relative "cap/nfs_client"
        Cap::NFSClient
      end

      guest_capability(:suse, :rsync_install) do
        require_relative "cap/rsync"
        Cap::RSync
      end

      guest_capability(:suse, :rsync_installed) do
        require_relative "cap/rsync"
        Cap::RSync
      end
    end
  end
end
