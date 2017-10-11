# A general Vagrant system implementation for "solaris 11".
#
# Contributed by Jan Thomas Moldung <janth@moldung.no>

require "vagrant"

module VagrantPlugins
  module GuestSolaris11
    class Plugin < Vagrant.plugin("2")
      name "Solaris 11 guest."
      description "Solaris 11 guest support."

      guest(:solaris11, :solaris) do
        require_relative "guest"
        Guest
      end

      config(:solaris11) do
        require_relative "config"
        Config
      end

      guest_capability(:solaris11, :change_host_name) do
        require_relative "cap/change_host_name"
        Cap::ChangeHostName
      end

      guest_capability(:solaris11, :configure_networks) do
        require_relative "cap/configure_networks"
        Cap::ConfigureNetworks
      end
    end
  end
end
