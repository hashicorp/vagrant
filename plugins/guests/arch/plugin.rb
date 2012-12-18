require "vagrant"

module VagrantPlugins
  module GuestArch
    class Plugin < Vagrant.plugin("2")
      name "Arch guest"
      description "Arch guest support."

      guest("arch") do
        require File.expand_path("../guest", __FILE__)
        Guest
      end
    end
  end
end
