require "vagrant"

module VagrantPlugins
  module GuestDebian
    class Plugin < Vagrant.plugin("2")
      name "Debian guest"
      description "Debian guest support."

      guest("debian", "linux") do
        require File.expand_path("../guest", __FILE__)
        Guest
      end

      guest_capability("debian", "configure_networks") do
        require_relative "cap/configure_networks"
        Cap::ConfigureNetworks
      end

      guest_capability("debian", "change_host_name") do
        require_relative "cap/change_host_name"
        Cap::ChangeHostName
      end

      guest_capability("debian", "nfs_client_install") do
        require_relative "cap/nfs_client"
        Cap::NFSClient
      end

      guest_capability("debian", "rsync_install") do
        require_relative "cap/rsync"
        Cap::RSync
      end
    end
  end
end
