require "vagrant"

module VagrantPlugins
  module GuestSlackware
    class Plugin < Vagrant.plugin("2")
      name "Slackware guest"
      description "Slackware guest support."

      guest(:slackware, :linux) do
        require_relative "guest"
        Guest
      end

      guest_capability(:slackware, :change_host_name) do
        require_relative "cap/change_host_name"
        Cap::ChangeHostName
      end

      guest_capability(:slackware, :configure_networks) do
        require_relative "cap/configure_networks"
        Cap::ConfigureNetworks
      end
    end
  end
end
