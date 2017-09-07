require "vagrant"

module VagrantPlugins
  module GuestALT
    class Plugin < Vagrant.plugin("2")
      name "ALT Platform guest"
      description "ALT Platform guest support."

      guest(:alt, :redhat) do
        require_relative "guest"
        Guest
      end

      guest_capability(:alt, :change_host_name) do
        require_relative "cap/change_host_name"
        Cap::ChangeHostName
      end

      guest_capability(:alt, :configure_networks) do
        require_relative "cap/configure_networks"
        Cap::ConfigureNetworks
      end

      guest_capability(:alt, :flavor) do
        require_relative "cap/flavor"
        Cap::Flavor
      end

      guest_capability(:alt, :network_scripts_dir) do
        require_relative "cap/network_scripts_dir"
        Cap::NetworkScriptsDir
      end

      guest_capability(:alt, :rsync_install) do
        require_relative "cap/rsync"
        Cap::RSync
      end
    end
  end
end
