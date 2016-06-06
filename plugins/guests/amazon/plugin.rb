require "vagrant"

module VagrantPlugins
  module GuestAmazon
    class Plugin < Vagrant.plugin("2")
      name "Amazon Linux guest"
      description "Amazon linux guest support."

      guest(:amazon, :redhat) do
        require_relative "guest"
        Guest
      end

      guest_capability(:amazon, :flavor) do
        require_relative "cap/flavor"
        Cap::Flavor
      end
    end
  end
end
