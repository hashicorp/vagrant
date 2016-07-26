require "vagrant"

module VagrantPlugins
  module GuestPld
    class Plugin < Vagrant.plugin("2")
      name "PLD Linux guest"
      description "PLD Linux guest support."

      guest(:pld, :redhat) do
        require_relative "guest"
        Guest
      end

      guest_capability(:pld, :change_host_name) do
        require_relative "cap/change_host_name"
        Cap::ChangeHostName
      end

      guest_capability(:pld, :network_scripts_dir) do
        require_relative "cap/network_scripts_dir"
        Cap::NetworkScriptsDir
      end

      guest_capability(:pld, :flavor) do
        require_relative "cap/flavor"
        Cap::Flavor
      end
    end
  end
end
