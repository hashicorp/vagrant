require "vagrant"

module VagrantPlugins
  module GuestOpenBSD
    class Plugin < Vagrant.plugin("2")
      name "OpenBSD guest"
      description "OpenBSD guest support."

      guest("openbsd") do
        require File.expand_path("../guest", __FILE__)
        Guest
      end
    end
  end
end
