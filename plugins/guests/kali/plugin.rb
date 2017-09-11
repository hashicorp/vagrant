require "vagrant"

module VagrantPlugins
  module GuestKali
    class Plugin < Vagrant.plugin("2")
      name "Kali guest"
      description "Kali guest support."

      guest(:kali, :debian) do
        require_relative "guest"
        Guest
      end
    end
  end
end
