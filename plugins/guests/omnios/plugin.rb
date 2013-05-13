require "vagrant"

module VagrantPlugins
  module GuestOmniOS
    class Plugin < Vagrant.plugin("2")
      name "OmniOS guest."
      description "OmniOS guest support."

      guest("omnios", "solaris")  do
        require File.expand_path("../guest", __FILE__)
        Guest
      end

      guest_capability("omnios", "change_host_name") do
        require_relative "cap/change_host_name"
        Cap::ChangeHostName
      end
    end
  end
end
