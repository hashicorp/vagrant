require "vagrant"

module VagrantPlugins
  module GuestSolaris
    class Plugin < Vagrant.plugin("2")
      name "Solaris guest."
      description "Solaris guest support."

      config("solaris") do
        require File.expand_path("../config", __FILE__)
        Config
      end

      guest("solaris")  do
        require File.expand_path("../guest", __FILE__)
        Guest
      end
    end
  end
end
