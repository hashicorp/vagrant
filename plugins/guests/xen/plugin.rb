require "vagrant"

module VagrantPlugins
  module GuestXen
    class Plugin < Vagrant.plugin("1")
      name "Ubuntu with Xen guest"
      description "Ubuntu with Xen guest support (disables shared folders)."

      guest("xen") do
        require File.expand_path("../guest", __FILE__)
        Guest
      end
    end
  end
end
