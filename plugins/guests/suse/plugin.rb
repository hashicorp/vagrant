require "vagrant"

module VagrantPlugins
  module GuestSuse
    class Plugin < Vagrant.plugin("2")
      name "SUSE guest"
      description "SUSE guest support."

      guest("suse") do
        require File.expand_path("../guest", __FILE__)
        Guest
      end
    end
  end
end
