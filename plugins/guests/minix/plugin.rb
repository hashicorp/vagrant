require "vagrant"

module VagrantPlugins
  module GuestMINIX
    class Plugin < Vagrant.plugin("2")
      name "MINIX guest"
      description "MINIX guest support."

      guest(:minix, :netbsd) do
        require_relative "guest"
        Guest
      end

      guest_capability(:minix, :change_host_name) do
        require_relative "cap/change_host_name"
        Cap::ChangeHostName
      end

      guest_capability(:minix, :rsync_install) do
        require_relative "cap/rsync"
        Cap::RSync
      end

      guest_capability(:minix, :rsync_command) do
        require_relative "cap/rsync"
        Cap::RSync
      end
    end
  end
end
