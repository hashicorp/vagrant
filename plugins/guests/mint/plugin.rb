require "vagrant"

module VagrantPlugins
  module GuestMint
    class Plugin < Vagrant.plugin("2")
      name "Mint guest"
      description "Mint guest support."

      guest("mint", "ubuntu") do
        require File.expand_path("../guest", __FILE__)
        Guest
      end
    end
  end
end
