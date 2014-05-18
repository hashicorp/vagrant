require "vagrant"

module VagrantPlugins
  module GuestNixos
    class Plugin < Vagrant.plugin("2")
      name "NixOS guest"
      description "NixOS guest support."

      guest("nixos", "linux") do
        require File.expand_path("../guest", __FILE__)
        Guest
      end

      guest_capability("nixos", "configure_networks") do
        require_relative "cap/configure_networks"
        Cap::ConfigureNetworks
      end

      guest_capability("nixos", "change_host_name") do
        require_relative "cap/change_host_name"
        Cap::ChangeHostName
      end
    end
  end
end
