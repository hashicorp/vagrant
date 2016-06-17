require "vagrant"

module VagrantPlugins
  module GuestCoreOS
    class Plugin < Vagrant.plugin("2")
      name "CoreOS guest"
      description "CoreOS guest support."

      guest(:coreos, :linux) do
        require_relative "guest"
        Guest
      end

      guest_capability(:coreos, :change_host_name) do
        require_relative "cap/change_host_name"
        Cap::ChangeHostName
      end

      guest_capability(:coreos, :configure_networks) do
        require_relative "cap/configure_networks"
        Cap::ConfigureNetworks
      end

      guest_capability(:coreos, :docker_daemon_running) do
        require_relative "cap/docker"
        Cap::Docker
      end
    end
  end
end
