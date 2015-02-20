require "vagrant"

module VagrantPlugins
  module GuestDebian8
    class Plugin < Vagrant.plugin("2")
      name "Debian Jessie guest"
      description "Debian Jessie guest support."

      guest("debian8", "debian") do
        require File.expand_path("../guest", __FILE__)
        Guest
      end

      guest_capability("debian8", "halt") do
        require_relative "cap/halt"
        Cap::Halt
      end

    end
  end
end
