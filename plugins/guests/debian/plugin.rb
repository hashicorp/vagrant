require "vagrant"

module VagrantPlugins
  module GuestDebian
    class Plugin < Vagrant.plugin("2")
      name "Debian guest"
      description "Debian guest support."

      guest("debian") do
        require File.expand_path("../guest", __FILE__)
        Guest
      end
    end
  end
end
