require "vagrant"

module VagrantPlugins
  module GuestFuntoo
    class Plugin < Vagrant.plugin("2")
      name "Funtoo guest"
      description "Funtoo guest support."

      guest(:funtoo, :gentoo) do
        require_relative "guest"
        Guest
      end

      guest_capability(:funtoo, :configure_networks) do
        require_relative "cap/configure_networks"
        Cap::ConfigureNetworks
      end
    end
  end
end
