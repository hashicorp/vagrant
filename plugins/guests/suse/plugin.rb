require "vagrant"

module VagrantPlugins
  module GuestSuse
    class Plugin < Vagrant.plugin("2")
      name "SUSE guest"
      description "SUSE guest support."

      guest("suse", "redhat") do
        require File.expand_path("../guest", __FILE__)
        Guest
      end

      guest_capability("suse", "change_host_name") do
        require_relative "cap/change_host_name"
        Cap::ChangeHostName
      end

      guest_capability("suse", "configure_networks") do
        require_relative "cap/configure_networks"
        Cap::ConfigureNetworks
      end

      guest_capability("suse", "network_scripts_dir") do
        require_relative "cap/network_scripts_dir"
        Cap::NetworkScriptsDir
      end
    end
  end
end
