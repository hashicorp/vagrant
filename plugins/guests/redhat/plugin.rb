require "vagrant"

module VagrantPlugins
  module GuestRedHat
    class Plugin < Vagrant.plugin("2")
      name "Red Hat Enterprise Linux guest"
      description "Red Hat Enterprise Linux guest support."

      guest(:redhat, :linux) do
        require_relative "guest"
        Guest
      end

      guest_capability(:redhat, :change_host_name) do
        require_relative "cap/change_host_name"
        Cap::ChangeHostName
      end

      guest_capability(:redhat, :configure_networks) do
        require_relative "cap/configure_networks"
        Cap::ConfigureNetworks
      end

      guest_capability(:redhat, :flavor) do
        require_relative "cap/flavor"
        Cap::Flavor
      end

      guest_capability(:redhat, :network_scripts_dir) do
        require_relative "cap/network_scripts_dir"
        Cap::NetworkScriptsDir
      end

      guest_capability(:redhat, :nfs_client_install) do
        require_relative "cap/nfs_client"
        Cap::NFSClient
      end

      guest_capability(:redhat, :rsync_install) do
        require_relative "cap/rsync"
        Cap::RSync
      end
    end
  end
end
