require "vagrant"

module VagrantPlugins
  module GuestFreeBSD
    class Plugin < Vagrant.plugin("2")
      name "FreeBSD guest"
      description "FreeBSD guest support."

      config("freebsd") do
        require File.expand_path("../config", __FILE__)
        Config
      end

      guest("freebsd")  do
        require File.expand_path("../guest", __FILE__)
        Guest
      end
    end
  end
end
