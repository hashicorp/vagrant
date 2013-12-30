require "vagrant"

module VagrantPlugins
  module GuestUbuntu
    class Plugin < Vagrant.plugin("2")
      name "Ubuntu guest"
      description "Ubuntu guest support."

      guest("ubuntu", "debian") do
        require File.expand_path("../guest", __FILE__)
        Guest
      end

      guest_capability("ubuntu", "change_host_name") do
        # ubuntu is just just a specialization of the debian code for this capability
        require_relative "../debian/cap/change_host_name"
        require_relative "cap/change_host_name"
        Cap::ChangeHostName
      end
    end
  end
end
