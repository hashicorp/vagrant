require "vagrant"

module VagrantPlugins
  module GuestPld
    class Plugin < Vagrant.plugin("2")
      name "PLD Linux guest"
      description "PLD Linux guest support."

      guest("pld") do
        require File.expand_path("../guest", __FILE__)
        Guest
      end
    end
  end
end
