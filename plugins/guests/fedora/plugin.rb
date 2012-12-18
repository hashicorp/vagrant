require "vagrant"

module VagrantPlugins
  module GuestFedora
    class Plugin < Vagrant.plugin("2")
      name "Fedora guest"
      description "Fedora guest support."

      guest("fedora") do
        require File.expand_path("../guest", __FILE__)
        Guest
      end
    end
  end
end
