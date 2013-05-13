require "vagrant"

module VagrantPlugins
  module GuestOpenBSD
    class Plugin < Vagrant.plugin("2")
      name "OpenBSD guest"
      description "OpenBSD guest support."

      guest("openbsd", "linux") do
        require File.expand_path("../guest", __FILE__)
        Guest
      end

      guest_capability("openbsd", "halt") do
        require_relative "cap/halt"
        Cap::Halt
      end
    end
  end
end
