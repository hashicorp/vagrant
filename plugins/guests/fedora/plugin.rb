require "vagrant"

module VagrantPlugins
  module GuestFedora
    class Plugin < Vagrant.plugin("1")
      name "Fedora guest"
      description "Fedora guest support."

      activated do
      end

      guest("fedora") do
        require File.expand_path("../guest", __FILE__)
        Guest
      end
    end
  end
end
