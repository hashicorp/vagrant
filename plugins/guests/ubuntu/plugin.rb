require "vagrant"

module VagrantPlugins
  module GuestUbuntu
    class Plugin < Vagrant.plugin("2")
      name "Ubuntu guest"
      description "Ubuntu guest support."

      guest(:ubuntu, :debian) do
        require_relative "guest"
        Guest
      end

      guest_capability(:ubuntu, :change_host_name) do
        require_relative "cap/change_host_name"
        Cap::ChangeHostName
      end
    end
  end
end
