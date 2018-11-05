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

      guest_capability(:haiku, :halt) do
        require_relative "cap/halt"
        Cap::Halt
      end

      guest_capability(:haiku, :change_host_name) do
        require_relative "cap/change_host_name"
        Cap::ChangeHostName
      end

      guest_capability(:haiku, :insert_public_key) do
        require_relative "cap/insert_public_key"
        Cap::InsertPublicKey
      end

      guest_capability(:haiku, :remove_public_key) do
        require_relative "cap/remove_public_key"
        Cap::RemovePublicKey
      end
    end
  end
end
