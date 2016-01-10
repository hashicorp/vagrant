require "vagrant"

module VagrantPlugins
  module GuestTrisquel
    class Plugin < Vagrant.plugin("2")
      name "Trisquel guest"
      description "Trisquel guest support."

      guest("trisquel", "ubuntu") do
        require File.expand_path("../guest", __FILE__)
        Guest
      end
    end
  end
end
