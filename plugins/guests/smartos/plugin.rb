require "vagrant"

module VagrantPlugins
  module GuestSmartOS
    class Plugin < Vagrant.plugin("2")
      name "SmartOS guest."
      description "SmartOS guest support."

      guest("smartos", "solaris")  do
        require File.expand_path("../guest", __FILE__)
        Guest
      end

      guest_capability("smartos", "change_host_name") do
        require_relative "cap/change_host_name"
        Cap::ChangeHostName
      end
    end
  end
end
