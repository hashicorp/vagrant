require "vagrant"

module VagrantPlugins
  module GuestFedora
    class Plugin < Vagrant.plugin("2")
      name "Fedora guest"
      description "Fedora guest support."

      guest("fedora", "redhat") do
        require File.expand_path("../guest", __FILE__)
        Guest
      end

      guest_capability("fedora", "configure_networks") do
        require_relative "cap/configure_networks"
        Cap::ConfigureNetworks
      end

      guest_capability("fedora", "network_scripts_dir") do
        require_relative "cap/network_scripts_dir"
        Cap::NetworkScriptsDir
      end
    end
  end
end
