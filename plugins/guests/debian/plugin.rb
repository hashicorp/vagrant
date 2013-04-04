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
    end
  end
end
