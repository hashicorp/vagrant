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
    end
  end
end
