require "vagrant"

module VagrantPlugins
  module GuestHaiku
    class Plugin < Vagrant.plugin("2")
      name "Haiku guest"
      description "Haiku guest support."

      guest(:haiku) do
        require_relative "guest"
        Guest
      end

      guest_capability(:haiku, :change_host_name) do
        require_relative "cap/change_host_name"
        Cap::ChangeHostName
      end
    end
  end
end
