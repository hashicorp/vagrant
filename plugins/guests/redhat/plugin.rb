require "vagrant"

module VagrantPlugins
  module GuestRedHat
    class Plugin < Vagrant.plugin("2")
      name "RedHat guest"
      description "RedHat guest support."

      guest("redhat", "linux") do
        require File.expand_path("../guest", __FILE__)
        Guest
      end

      guest_capability("redhat", "change_host_name") do
        require_relative "cap/change_host_name"
        Cap::ChangeHostName
      end

      guest_capability("redhat", "configure_networks") do
        require_relative "cap/configure_networks"
        Cap::ConfigureNetworks
      end

      guest_capability("redhat", "network_scripts_dir") do
        require_relative "cap/network_scripts_dir"
        Cap::NetworkScriptsDir
      end
    end
  end
end
