require "vagrant"

module VagrantPlugins
  module GuestPhoton
    class Plugin < Vagrant.plugin("2")
      name "VMware Photon guest"
      description "VMware Photon guest support."

      guest(:photon, :linux) do
        require_relative "guest"
        Guest
      end

      guest_capability(:photon, :change_host_name) do
        require_relative "cap/change_host_name"
        Cap::ChangeHostName
      end

      guest_capability(:photon, :configure_networks) do
        require_relative "cap/configure_networks"
        Cap::ConfigureNetworks
      end

      guest_capability(:photon, :docker_daemon_running) do
        require_relative "cap/docker"
        Cap::Docker
      end
    end
  end
end
