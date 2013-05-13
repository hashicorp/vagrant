require "vagrant"

module VagrantPlugins
  module GuestGentoo
    class Plugin < Vagrant.plugin("2")
      name "Gentoo guest"
      description "Gentoo guest support."

      guest("gentoo", "linux") do
        require File.expand_path("../guest", __FILE__)
        Guest
      end

      guest_capability("gentoo", "change_host_name") do
        require_relative "cap/change_host_name"
        Cap::ChangeHostName
      end

      guest_capability("gentoo", "configure_networks") do
        require_relative "cap/configure_networks"
        Cap::ConfigureNetworks
      end
    end
  end
end
