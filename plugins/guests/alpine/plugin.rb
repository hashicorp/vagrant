require "vagrant"

module VagrantPlugins
  module GuestAlpine
    class Plugin < Vagrant.plugin("2")
      name "Alpine guest"
      description "Alpine guest support."

      guest("alpine", "linux") do
        require File.expand_path("../guest", __FILE__)
        Guest
      end

      guest_capability("alpine", "halt") do
        require_relative "cap/halt"
        Cap::Halt
      end
    end
  end
end
