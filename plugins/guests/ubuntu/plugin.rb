require "vagrant"

module VagrantPlugins
  module GuestUbuntu
    class Plugin < Vagrant.plugin("1")
      name "Ubuntu guest"
      description "Ubuntu guest support."

      guest("ubuntu") do
        require File.expand_path("../guest", __FILE__)
        Guest
      end
    end
  end
end
