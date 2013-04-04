require "vagrant"

module VagrantPlugins
  module GuestArch
    class Plugin < Vagrant.plugin("2")
      name "Arch guest"
      description "Arch guest support."

      guest("arch", "linux") do
        require File.expand_path("../guest", __FILE__)
        Guest
      end

      guest_capability("arch", "change_host_name") do
        require_relative "cap/change_host_name"
        Cap::ChangeHostName
      end

      guest_capability("arch", "configure_networks") do
        require_relative "cap/configure_networks"
        Cap::ConfigureNetworks
      end
    end
  end
end
