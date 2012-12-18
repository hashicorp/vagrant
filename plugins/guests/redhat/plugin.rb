require "vagrant"

module VagrantPlugins
  module GuestRedHat
    class Plugin < Vagrant.plugin("2")
      name "RedHat guest"
      description "RedHat guest support."

      guest("redhat") do
        require File.expand_path("../guest", __FILE__)
        Guest
      end
    end
  end
end
