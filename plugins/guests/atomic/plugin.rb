require "vagrant"

module VagrantPlugins
  module GuestAtomic
    class Plugin < Vagrant.plugin("2")
      name "Atomic Host guest"
      description "Atomic Host guest support."

      guest(:atomic, :fedora) do
        require_relative "guest"
        Guest
      end

      guest_capability(:atomic, :change_host_name) do
        require_relative "cap/change_host_name"
        Cap::ChangeHostName
      end

      guest_capability(:atomic, :docker_daemon_running) do
        require_relative "cap/docker"
        Cap::Docker
      end
    end
  end
end
