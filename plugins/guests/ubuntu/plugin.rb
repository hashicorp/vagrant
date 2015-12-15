require "vagrant"

module VagrantPlugins
  module GuestUbuntu
    class Plugin < Vagrant.plugin("2")
      name "Ubuntu guest"
      description "Ubuntu guest support."

      guest("ubuntu", "debian") do
        require File.expand_path("../guest", __FILE__)
        Guest
      end

      guest_capability("ubuntu", "change_host_name") do
        # ubuntu is just just a specialization of the debian code for this capability
        require_relative "../debian/cap/change_host_name"
        require_relative "cap/change_host_name"
        Cap::ChangeHostName
      end

      guest_capability("ubuntu", "configure_networks") do
        require_relative "../debian/cap/configure_networks"
        require_relative "cap/configure_networks"
        Cap::ConfigureNetworks
      end
    end
  end
end
