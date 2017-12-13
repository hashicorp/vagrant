require "vagrant"

module VagrantPlugins
  module GuestDragonFlyBSD
    class Plugin < Vagrant.plugin("2")
      name "DragonFly BSD guest"
      description "DragonFly BSD guest support."

      guest(:dragonflybsd, :freebsd) do
        require_relative "guest"
        Guest
      end
    end
  end
end
