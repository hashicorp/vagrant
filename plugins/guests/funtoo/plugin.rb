require "vagrant"

module VagrantPlugins
  module GuestFuntoo
    class Plugin < Vagrant.plugin("2")
      name "Funtoo guest"
      description "Funtoo guest support."

      guest("funtoo", "linux") do
        require File.expand_path("../guest", __FILE__)
        Guest
      end

      guest_capability("funtoo", "change_host_name") do
        require_relative "cap/change_host_name"
        Cap::ChangeHostName
      end

      guest_capability("funtoo", "configure_networks") do
        require_relative "cap/configure_networks"
        Cap::ConfigureNetworks
      end
    end
  end
end
