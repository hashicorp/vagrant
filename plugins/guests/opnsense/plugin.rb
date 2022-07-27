require "vagrant"

module VagrantPlugins
  module GuestOPNsense
    class Plugin < Vagrant.plugin("2")
      name "OPNsense guest"
      description "OPNsense guest support."

      guest(:opnsense, :bsd) do
        require_relative "guest"
        Guest
      end

    end
  end
end
