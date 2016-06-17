require "vagrant"

module VagrantPlugins
  module GuestNixos
    class Plugin < Vagrant.plugin("2")
      name "NixOS guest"
      description "NixOS guest support."

      guest(:nixos, :linux) do
        require_relative "guest"
        Guest
      end

      guest_capability(:nixos, :configure_networks) do
        require_relative "cap/configure_networks"
        Cap::ConfigureNetworks
      end

      guest_capability(:nixos, :change_host_name) do
        require_relative "cap/change_host_name"
        Cap::ChangeHostName
      end

      guest_capability(:nixos, :nfs_client_installed) do
        require_relative "cap/nfs_client"
        Cap::NFSClient
      end
    end
  end
end
