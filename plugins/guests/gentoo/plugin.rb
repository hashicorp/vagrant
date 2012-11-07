require "vagrant"

module VagrantPlugins
  module GuestGentoo
    class Plugin < Vagrant.plugin("2")
      name "Gentoo guest"
      description "Gentoo guest support."

      guest("gentoo") do
        require File.expand_path("../guest", __FILE__)
        Guest
      end
    end
  end
end
