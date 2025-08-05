require "vagrant"

module VagrantPlugins
  module GuestUos
    class Plugin < Vagrant.plugin("2")
      name "Uos guest"
      description "Uos guest support."

      guest(:uos, :redhat) do
        require_relative "guest"
        Guest
      end

      guest_capability(:uos, :flavor) do
        require_relative "cap/flavor"
        Cap::Flavor
      end
    end
  end
end
